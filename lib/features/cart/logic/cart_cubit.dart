import 'package:bloc/bloc.dart';
import 'package:coffix_app/core/extensions/product_extensions.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_cubit.freezed.dart';
part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  Map<String, String>? selectedByGroup;
  CartCubit() : super(CartState());

  void addProduct({required CartItem newItem}) {
    final Cart? currentCart = state.cart;

    // 1. if no cart yet -> create cart
    if (currentCart == null) {
      emit(
        state.copyWith(
          cart: Cart(storeId: newItem.storeId, items: [newItem], duration: 0),
        ),
      );
      return;
    }

    // 2. cart is store-scopred -> block or clear when store changes
    if (currentCart.storeId != newItem.storeId) {
      throw Exception('Cannot add product to different store cart');
    }

    // 3. merge identical config by cartItemId
    final index =
        currentCart.items?.indexWhere((item) => item.id == newItem.id) ?? -1;
    if (index == -1) {
      emit(
        state.copyWith(
          cart: currentCart.copyWith(
            items: [...currentCart.items ?? [], newItem],
          ),
        ),
      );
      return;
    }

    final CartItem existing =
        currentCart.items?[index] ??
        CartItem(
          id: '',
          storeId: '',
          productId: '',
          productName: '',
          productImageUrl: '',
          quantity: 0,
          selectedByGroup: {},
          basePrice: 0,
          modifierPriceSnapshot: {},
          unitTotal: 0,
          lineTotal: 0,
          createdAt: DateTime.now(),
        );
    final int newQuantity = (existing.quantity ?? 0) + (newItem.quantity ?? 0);

    final updated = existing.copyWith(
      quantity: newQuantity,
      lineTotal: existing.unitTotal * newQuantity,
    );

    final List<CartItem> updatedItems = [...currentCart.items ?? []]
      ..[index] = updated;

    emit(state.copyWith(cart: currentCart.copyWith(items: updatedItems)));
  }

  void updateProduct({
    required String cartItemId,
    required CartItem updatedItem,
  }) {
    final Cart? currentCart = state.cart;
    if (currentCart == null) return;
    final index =
        currentCart.items?.indexWhere((item) => item.id == cartItemId) ?? -1;
    if (index == -1) return;
    final List<CartItem> updatedItems = [...?currentCart.items]
      ..[index] = updatedItem;
    emit(state.copyWith(cart: currentCart.copyWith(items: updatedItems)));
  }

  void removeProduct({required String cartItemId}) {
    final Cart? currentCart = state.cart;
    if (currentCart == null) return;
    final newItems =
        currentCart.items?.where((item) => item.id != cartItemId) ?? [];
    if (newItems.isEmpty) {
      emit(state.copyWith(cart: null));
    } else {
      emit(
        state.copyWith(cart: currentCart.copyWith(items: newItems.toList())),
      );
    }
  }

  void resetCart() {
    emit(state.copyWith(cart: null));
  }

  /// Reconciles the cart when the preferred store changes to [newStoreId].
  /// Removes items not available at the new store and re-stamps kept items
  /// (storeId + recomputed id) so the cart is usable at the new store.
  /// Returns the number of items removed.
  int reconcileForStore({
    required String newStoreId,
    required List<ProductWithCategory> catalog,
  }) {
    final Cart? currentCart = state.cart;
    final items = currentCart?.items;
    if (currentCart == null || items == null || items.isEmpty) return 0;

    // Already on this store -> nothing to do.
    if (currentCart.storeId == newStoreId) return 0;

    // Without a loaded catalog we cannot tell what is available, so keep
    // everything but still re-stamp so the cart stays usable at the new store.
    final Set<String>? availableProductIds = catalog.isEmpty
        ? null
        : catalog
              .productsByStore(
                storeId: newStoreId,
                preferredStoreId: newStoreId,
              )
              .map((p) => p.product.docId)
              .whereType<String>()
              .toSet();

    final helper = CartHelper();
    final kept = <CartItem>[];
    for (final item in items) {
      final productId = item.productId;
      if (productId == null) continue;
      final isAvailable =
          availableProductIds == null ||
          availableProductIds.contains(productId);
      if (!isAvailable) continue;

      // Re-stamp to the new store (storeId + recomputed hashed id).
      final newId = helper.buildCartItemIdHashed(
        storeId: newStoreId,
        productId: productId,
        selectedByGroup: item.selectedByGroup,
      );
      kept.add(item.reStamped(storeId: newStoreId, id: newId));
    }

    final removedCount = items.length - kept.length;

    if (kept.isEmpty) {
      emit(state.copyWith(cart: null));
    } else {
      emit(
        state.copyWith(
          cart: currentCart.copyWith(storeId: newStoreId, items: kept),
        ),
      );
    }
    return removedCount;
  }

  void pickTime(double duration) {
    emit(state.copyWith(cart: state.cart?.copyWith(duration: duration)));
  }

  void setPaymentMethod(PaymentMethod paymentMethod) {
    emit(
      state.copyWith(cart: state.cart?.copyWith(paymentMethod: paymentMethod)),
    );
  }
}
