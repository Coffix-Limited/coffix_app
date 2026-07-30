import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/data/repositories/modifier_repository.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:collection/collection.dart';

/// Outcome of rebuilding a past order (or draft) into cart items.
class ReorderResult {
  const ReorderResult({required this.items, required this.skippedItems, required this.droppedModifiers});

  /// Items that are still orderable and ready to be added to the cart.
  final List<CartItem> items;

  /// Number of source items dropped entirely because the product no longer
  /// exists, was deleted, or is not available at the selected store.
  final int skippedItems;

  /// Number of modifier selections stripped because the modifier or its group
  /// was deleted or disabled for the selected store.
  final int droppedModifiers;

  bool get isEmpty => items.isEmpty;
}

/// A single source line normalized from either an [Order] item or a [CartItem].
class _SourceItem {
  const _SourceItem({required this.productId, required this.quantity, required this.selectedByGroup});

  final String? productId;
  final int quantity;

  /// groupId -> modifierId, as captured when the order/draft was created.
  final Map<String, String> selectedByGroup;
}

/// Rebuilds cart items from a past order or a saved draft.
///
/// Selections are validated against the *live* catalog rather than the
/// historical snapshot, so products, modifier groups, and modifiers that have
/// since been soft-deleted (`isDeleted: true`) or disabled for the store are
/// not resurrected. A deleted modifier drops off the item while the product is
/// kept, with the price recomputed from live values.
///
/// This class is intentionally free of `BuildContext` — callers own reading
/// cubits, resetting the cart, notifications, and navigation.
class Reorder {
  Reorder({ModifierRepository? modifierRepository})
    : _modifierRepository = modifierRepository ?? getIt<ModifierRepository>();

  final ModifierRepository _modifierRepository;
  final CartHelper _helper = CartHelper();

  /// Rebuilds the items of a past [order] for [storeId].
  Future<ReorderResult> fromOrder({
    required Order order,
    required String storeId,
    required List<ProductWithCategory> catalog,
  }) {
    final sources = (order.items ?? [])
        .map(
          (item) => _SourceItem(
            productId: item.productId,
            quantity: item.quantity ?? 1,
            selectedByGroup: item.selectedModifiers ?? const {},
          ),
        )
        .toList();

    return _build(sources: sources, storeId: storeId, catalog: catalog);
  }

  /// Rebuilds the items of a saved draft [cart] for [storeId].
  Future<ReorderResult> fromCart({
    required Cart cart,
    required String storeId,
    required List<ProductWithCategory> catalog,
  }) {
    final sources = (cart.items ?? [])
        .map(
          (item) => _SourceItem(
            productId: item.productId,
            quantity: item.quantity ?? 1,
            selectedByGroup: item.selectedByGroup,
          ),
        )
        .toList();

    return _build(sources: sources, storeId: storeId, catalog: catalog);
  }

  Future<ReorderResult> _build({
    required List<_SourceItem> sources,
    required String storeId,
    required List<ProductWithCategory> catalog,
  }) async {
    final List<CartItem> items = [];
    int skippedItems = 0;
    int droppedModifiers = 0;

    // Live modifiers per product, keyed by productId. Cached so an order with
    // the same product on several lines only hits Firestore once.
    final Map<String, Map<String, Modifier>> liveModifiersByProduct = {};

    for (final source in sources) {
      final productId = source.productId;
      if (productId == null || productId.isEmpty) {
        skippedItems++;
        continue;
      }

      // Deleted products are already filtered out of the catalog by
      // ProductRepositoryImpl, so a missing match covers that case too.
      final match = catalog.firstWhereOrNull((p) => p.product.docId == productId);
      if (match == null) {
        skippedItems++;
        continue;
      }

      final product = match.product;

      final disabledStores = product.disabledStores;
      final availableStores = product.availableToStores;
      if (disabledStores != null && disabledStores.contains(storeId)) {
        skippedItems++;
        continue;
      }
      if (availableStores != null && !availableStores.contains(storeId)) {
        skippedItems++;
        continue;
      }

      final selectedByGroup = source.selectedByGroup;
      final Map<String, String> liveSelectedByGroup = {};
      Map<String, Modifier> modifierMap = {};

      if (selectedByGroup.isNotEmpty) {
        modifierMap = liveModifiersByProduct[productId] ??= await _liveModifiers(storeId: storeId, product: product);

        for (final entry in selectedByGroup.entries) {
          final modifier = modifierMap[entry.value];
          // Keep the selection only when the modifier still exists and still
          // belongs to a live group of this product at this store.
          if (modifier != null && modifier.groupId == entry.key) {
            liveSelectedByGroup[entry.key] = entry.value;
          } else {
            droppedModifiers++;
          }
        }
      }

      final modifierPriceSnapshot = _helper.buildModifierPriceSnapshot(
        selectedByGroup: liveSelectedByGroup,
        modifierMap: modifierMap,
      );
      final modifierLabelSnapshot = _helper.buildModifierLabelSnapshot(
        selectedByGroup: liveSelectedByGroup,
        modifierMap: modifierMap,
      );
      final basePrice = product.price ?? 0;
      final unitTotal = _helper.computeUnitTotal(basePrice: basePrice, modifierPriceSnapshot: modifierPriceSnapshot);
      final quantity = source.quantity;
      // Hash from the filtered selection so a stripped item merges with an
      // identical line already in the cart.
      final id = _helper.buildCartItemIdHashed(
        storeId: storeId,
        productId: productId,
        selectedByGroup: liveSelectedByGroup,
      );

      items.add(
        CartItem(
          id: id,
          storeId: storeId,
          productId: productId,
          productName: product.name ?? '',
          productImageUrl: product.imageUrl ?? '',
          quantity: quantity,
          selectedByGroup: liveSelectedByGroup,
          basePrice: basePrice,
          modifierPriceSnapshot: modifierPriceSnapshot,
          modifierLabelSnapshot: modifierLabelSnapshot,
          unitTotal: unitTotal,
          lineTotal: unitTotal * quantity,
          createdAt: TimeUtils.now(),
        ),
      );
    }

    return ReorderResult(items: items, skippedItems: skippedItems, droppedModifiers: droppedModifiers);
  }

  /// Live, orderable modifiers for [product] at [storeId], keyed by modifier id
  /// and stamped with the id of the bundle group they belong to.
  ///
  /// `getCustomizationBundles` already drops deleted groups, deleted modifiers,
  /// and anything disabled by the store's product override.
  Future<Map<String, Modifier>> _liveModifiers({required String storeId, required Product product}) async {
    try {
      final bundles = await _modifierRepository.getCustomizationBundles(storeId: storeId, product: product);

      return {
        for (final bundle in bundles)
          for (final modifier in bundle.modifiers)
            if (modifier.docId != null) modifier.docId!: modifier.copyWith(groupId: bundle.group.docId),
      };
    } catch (_) {
      // Without the live catalog we cannot prove a modifier still exists, so
      // treat every selection as unavailable rather than resurrecting one.
      return {};
    }
  }
}
