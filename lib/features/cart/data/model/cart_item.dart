import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_item.g.dart';

@JsonSerializable()
class CartItem extends Equatable {
  final String id;
  final String storeId;
  final String productId;
  final String productName;
  final String productImageUrl;

  final int quantity;

  final Map<String, String> selectedByGroup;
  final double basePrice;
  final Map<String, double> modifierPriceSnapshot;
  final Map<String, String> modifierLabelSnapshot;

  final double unitTotal;
  final double lineTotal;

  final DateTime createdAt;

  const CartItem({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.selectedByGroup,
    required this.basePrice,
    required this.modifierPriceSnapshot,
    this.modifierLabelSnapshot = const {},
    required this.unitTotal,
    required this.lineTotal,
    required this.createdAt,
  });

  /// Builds a [CartItem] from add-product context: [product], [quantity], [storeId], and selected [modifiers].
  static CartItem fromSelection({
    required Product product,
    required int quantity,
    required String storeId,
    required List<Modifier> modifiers,
  }) {
    final productId = product.docId ?? '';
    final selectedByGroup = {
      for (final m in modifiers)
        if (m.groupId != null && m.docId != null) m.groupId!: m.docId!
    };
    final helper = CartHelper();
    final id = helper.buildCartItemIdHashed(
      storeId: storeId,
      productId: productId,
      selectedByGroup: selectedByGroup,
    );
    final modifierMap = {for (final m in modifiers) if (m.docId != null) m.docId!: m};
    final modifierPriceSnapshot = helper.buildModifierPriceSnapshot(
      selectedByGroup: selectedByGroup,
      modifierMap: modifierMap,
    );
    final modifierLabelSnapshot = {
      for (final m in modifiers)
        if (m.docId != null && m.label != null) m.docId!: m.label!
    };
    final basePrice = product.price ?? 0;
    final unitTotal = helper.computeUnitTotal(
      basePrice: basePrice,
      modifierPriceSnapshot: modifierPriceSnapshot,
    );
    final lineTotal = unitTotal * quantity;
    final now = DateTime.now();
    return CartItem(
      id: id,
      storeId: storeId,
      productId: productId,
      productName: product.name ?? '',
      productImageUrl: product.imageUrl ?? '',
      quantity: quantity,
      selectedByGroup: selectedByGroup,
      basePrice: basePrice,
      modifierPriceSnapshot: modifierPriceSnapshot,
      modifierLabelSnapshot: modifierLabelSnapshot,
      unitTotal: unitTotal,
      lineTotal: lineTotal,
      createdAt: now,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  @override
  List<Object?> get props => [id];

  CartItem copyWith({
    int? quantity,
    Map<String, String>? selectedByGroup,
    double? basePrice,
    Map<String, double>? modifierPriceSnapshot,
    Map<String, String>? modifierLabelSnapshot,
    double? unitTotal,
    double? lineTotal,
    DateTime? createdAt,
  }) => CartItem(
    id: id,
    storeId: storeId,
    productId: productId,
    productName: productName,
    productImageUrl: productImageUrl,
    quantity: quantity ?? this.quantity,
    selectedByGroup: selectedByGroup ?? this.selectedByGroup,
    basePrice: basePrice ?? this.basePrice,
    modifierPriceSnapshot: modifierPriceSnapshot ?? this.modifierPriceSnapshot,
    modifierLabelSnapshot: modifierLabelSnapshot ?? this.modifierLabelSnapshot,
    unitTotal: unitTotal ?? this.unitTotal,
    lineTotal: lineTotal ?? this.lineTotal,
    createdAt: createdAt ?? this.createdAt,
  );
}
