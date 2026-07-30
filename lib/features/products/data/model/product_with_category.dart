import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:coffix_app/features/products/data/model/product_category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_with_category.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductWithCategory {
  final Product product;
  final ProductCategory? category;

  ProductWithCategory({required this.product, this.category});

  factory ProductWithCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductWithCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ProductWithCategoryToJson(this);

  List<ProductWithCategory> productsByStore(String storeId) {
    return product.availableToStores?.contains(storeId) ?? false ? [this] : [];
  }
}
