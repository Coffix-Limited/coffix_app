import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:coffix_app/core/utils/double_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_category.g.dart';

@JsonSerializable()
class ProductCategory {
  final String? docId;
  final String? imageUrl;
  final String? name;
  @DoubleConverter()
  final double? order;
  final bool? isDeleted;
  @DateTimeConverter()
  final DateTime? deletedAt;

  ProductCategory({this.docId, this.imageUrl, this.name, this.order, this.isDeleted, this.deletedAt});

  factory ProductCategory.fromJson(Map<String, dynamic> json) => _$ProductCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCategoryToJson(this);
}
