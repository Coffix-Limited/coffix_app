import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'draft.g.dart';

@JsonSerializable(explicitToJson: true)
class Draft {
  final String? id;
  final Cart? cart;
  @DateTimeConverter()
  final DateTime? createdAt;
  @DateTimeConverter()
  final DateTime? updatedAt;

  Draft({this.id, this.cart, this.createdAt, this.updatedAt});

  factory Draft.fromJson(Map<String, dynamic> json) => _$DraftFromJson(json);
  Map<String, dynamic> toJson() => _$DraftToJson(this);
}
