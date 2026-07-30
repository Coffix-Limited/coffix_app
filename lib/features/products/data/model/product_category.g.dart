// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductCategory _$ProductCategoryFromJson(Map<String, dynamic> json) =>
    ProductCategory(
      docId: json['docId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      name: json['name'] as String?,
      order: const DoubleConverter().fromJson(json['order']),
      isDeleted: json['isDeleted'] as bool?,
      deletedAt: const DateTimeConverter().fromJson(json['deletedAt']),
    );

Map<String, dynamic> _$ProductCategoryToJson(ProductCategory instance) =>
    <String, dynamic>{
      'docId': instance.docId,
      'imageUrl': instance.imageUrl,
      'name': instance.name,
      'order': const DoubleConverter().toJson(instance.order),
      'isDeleted': instance.isDeleted,
      'deletedAt': const DateTimeConverter().toJson(instance.deletedAt),
    };
