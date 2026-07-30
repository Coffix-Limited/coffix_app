// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_with_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductWithCategory _$ProductWithCategoryFromJson(Map<String, dynamic> json) =>
    ProductWithCategory(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      category: json['category'] == null
          ? null
          : ProductCategory.fromJson(json['category'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProductWithCategoryToJson(
  ProductWithCategory instance,
) => <String, dynamic>{
  'product': instance.product.toJson(),
  'category': instance.category?.toJson(),
};
