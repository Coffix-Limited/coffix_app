import 'package:coffix_app/core/utils/reorder.dart';
import 'package:coffix_app/data/repositories/modifier_repository.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/features/modifier/data/model/modifier_group.dart';
import 'package:coffix_app/features/modifier/data/model/modifier_group_bundle.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Returns whatever bundles the test hands it, standing in for the live catalog.
class _FakeModifierRepository implements ModifierRepository {
  _FakeModifierRepository(this.bundles);

  final List<ModifierGroupBundle> bundles;

  @override
  Future<List<ModifierGroupBundle>> getCustomizationBundles({
    required String storeId,
    required Product product,
  }) async => bundles;

  @override
  Future<List<ModifierGroup>> getModifierGroups({
    required List<String> groupIds,
  }) async => bundles.map((b) => b.group).toList();

  @override
  Future<List<Modifier>> getModifiersByIds({
    required List<String> modifierIds,
  }) async => bundles.expand((b) => b.modifiers).toList();
}

void main() {
  // CartItem stamps createdAt via TimeUtils.now(), which reads tz.local.
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Pacific/Auckland'));
  });

  const storeId = 'store-1';
  const productId = 'product-1';
  const groupId = 'group-milk';
  const modifierId = 'mod-oat';

  final product = Product(
    docId: productId,
    name: 'Latte',
    price: 5.0,
    modifierGroupIds: [groupId],
  );
  final catalog = [ProductWithCategory(product: product)];

  final oatMilk = Modifier(
    docId: modifierId,
    groupId: groupId,
    label: 'Oat Milk',
    priceDelta: 1.5,
  );
  final milkGroup = ModifierGroup(
    docId: groupId,
    name: 'Milk',
    modifierIds: [modifierId],
  );

  /// A past order for one Latte with Oat Milk selected.
  final order = Order(
    items: [
      Item(
        productId: productId,
        productName: 'Latte',
        quantity: 2,
        selectedModifiers: {groupId: modifierId},
        modifiers: [
          ItemModifier(
            modifierId: modifierId,
            name: 'Oat Milk',
            priceDelta: 1.5,
          ),
        ],
      ),
    ],
  );

  Reorder reorderWith(List<ModifierGroupBundle> bundles) =>
      Reorder(modifierRepository: _FakeModifierRepository(bundles));

  test('keeps the modifier when it is still live', () async {
    final result = await reorderWith([
      ModifierGroupBundle(group: milkGroup, modifiers: [oatMilk]),
    ]).fromOrder(order: order, storeId: storeId, catalog: catalog);

    expect(result.items, hasLength(1));
    expect(result.droppedModifiers, 0);

    final item = result.items.single;
    expect(item.selectedByGroup, {groupId: modifierId});
    expect(item.modifierPriceSnapshot[modifierId], 1.5);
    expect(item.modifierLabelSnapshot[modifierId], 'Oat Milk');
    expect(item.unitTotal, 6.5); // 5.00 base + 1.50 modifier
    expect(item.lineTotal, 13.0); // x2
  });

  test('drops a deleted modifier but keeps the product', () async {
    // The group survives, but the modifier is gone from it.
    final result = await reorderWith([
      ModifierGroupBundle(group: milkGroup, modifiers: const []),
    ]).fromOrder(order: order, storeId: storeId, catalog: catalog);

    expect(result.items, hasLength(1));
    expect(result.droppedModifiers, 1);

    final item = result.items.single;
    expect(item.selectedByGroup, isEmpty);
    expect(item.modifierPriceSnapshot, isEmpty);
    expect(item.unitTotal, 5.0); // base price only
    expect(item.lineTotal, 10.0);
  });

  test('drops the modifier when its group is deleted', () async {
    // No bundles at all — the group no longer resolves.
    final result = await reorderWith(
      const [],
    ).fromOrder(order: order, storeId: storeId, catalog: catalog);

    expect(result.items, hasLength(1));
    expect(result.droppedModifiers, 1);
    expect(result.items.single.selectedByGroup, isEmpty);
    expect(result.items.single.unitTotal, 5.0);
  });

  test('skips the item when the product is not in the catalog', () async {
    final result = await reorderWith([
      ModifierGroupBundle(group: milkGroup, modifiers: [oatMilk]),
    ]).fromOrder(order: order, storeId: storeId, catalog: const []);

    expect(result.items, isEmpty);
    expect(result.isEmpty, isTrue);
    expect(result.skippedItems, 1);
  });

  test('skips the item when the product is disabled for the store', () async {
    final disabled = [
      ProductWithCategory(
        product: Product(
          docId: productId,
          name: 'Latte',
          price: 5.0,
          modifierGroupIds: [groupId],
          disabledStores: [storeId],
        ),
      ),
    ];

    final result = await reorderWith([
      ModifierGroupBundle(group: milkGroup, modifiers: [oatMilk]),
    ]).fromOrder(order: order, storeId: storeId, catalog: disabled);

    expect(result.items, isEmpty);
    expect(result.skippedItems, 1);
  });

  test('uses live prices rather than the historical snapshot', () async {
    final repriced = Modifier(
      docId: modifierId,
      groupId: groupId,
      label: 'Oat Milk',
      priceDelta: 2.5, // was 1.50 when the order was placed
    );

    final result = await reorderWith([
      ModifierGroupBundle(group: milkGroup, modifiers: [repriced]),
    ]).fromOrder(order: order, storeId: storeId, catalog: catalog);

    expect(result.items.single.modifierPriceSnapshot[modifierId], 2.5);
    expect(result.items.single.unitTotal, 7.5);
  });
}
