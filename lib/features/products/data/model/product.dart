import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.g.dart';

@JsonSerializable(explicitToJson: true)
class Product {
  final List<String>? availableToStores;
  final String? categoryId;
  final double? cost;
  final String? docId;
  final String? imageUrl;
  final List<String>? modifierGroupIds;
  final String? name;
  final double? order;
  final double? price;
  final String? categoryName;
  final bool? disabledPermanently;
  final List<String>? disabledStores;
  final bool? isDeleted;
  @DateTimeConverter()
  final DateTime? deletedAt;

  Product({
    this.availableToStores,
    this.categoryId,
    this.cost,
    this.docId,
    this.imageUrl,
    this.modifierGroupIds,
    this.name,
    this.order,
    this.price,
    this.categoryName,
    this.disabledPermanently,
    this.disabledStores,
    this.isDeleted,
    this.deletedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    String? categoryName,
    List<String>? availableToStores,
    String? categoryId,
    double? cost,
    String? docId,
    String? imageUrl,
    List<String>? modifierGroupIds,
    String? name,
    double? order,
    double? price,
  }) => Product(
    categoryName: categoryName ?? this.categoryName,
    availableToStores: availableToStores ?? this.availableToStores,
    categoryId: categoryId,
    cost: cost,
    docId: docId,
    imageUrl: imageUrl,
    modifierGroupIds: modifierGroupIds,
    name: name,
    order: order,
    price: price,
  );
}
