// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Draft _$DraftFromJson(Map<String, dynamic> json) => Draft(
  id: json['id'] as String?,
  cart: json['cart'] == null
      ? null
      : Cart.fromJson(json['cart'] as Map<String, dynamic>),
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$DraftToJson(Draft instance) => <String, dynamic>{
  'id': instance.id,
  'cart': instance.cart?.toJson(),
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
};
