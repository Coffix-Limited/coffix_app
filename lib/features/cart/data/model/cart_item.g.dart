// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  id: json['id'] as String,
  storeId: json['storeId'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  productImageUrl: json['productImageUrl'] as String,
  quantity: (json['quantity'] as num).toInt(),
  selectedByGroup: Map<String, String>.from(json['selectedByGroup'] as Map),
  basePrice: (json['basePrice'] as num).toDouble(),
  modifierPriceSnapshot: (json['modifierPriceSnapshot'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(k, (e as num).toDouble())),
  modifierLabelSnapshot: (json['modifierLabelSnapshot'] as Map<String, dynamic>?)
          ?.map((k, e) => MapEntry(k, e as String)) ??
      const {},
  unitTotal: (json['unitTotal'] as num).toDouble(),
  lineTotal: (json['lineTotal'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'productId': instance.productId,
  'productName': instance.productName,
  'productImageUrl': instance.productImageUrl,
  'quantity': instance.quantity,
  'selectedByGroup': instance.selectedByGroup,
  'basePrice': instance.basePrice,
  'modifierPriceSnapshot': instance.modifierPriceSnapshot,
  'modifierLabelSnapshot': instance.modifierLabelSnapshot,
  'unitTotal': instance.unitTotal,
  'lineTotal': instance.lineTotal,
  'createdAt': instance.createdAt.toIso8601String(),
};
