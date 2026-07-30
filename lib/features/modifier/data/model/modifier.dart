import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'modifier.g.dart';

@JsonSerializable()
class Modifier {
  final String? docId;
  final String? groupId;
  final bool? isDefault;
  final String? label;
  final double? priceDelta;
  final double? order;
  final bool? isDeleted;
  @DateTimeConverter()
  final DateTime? deletedAt;

  Modifier({
    this.docId,
    this.groupId,
    this.isDefault,
    this.label,
    this.priceDelta,
    this.order,
    this.isDeleted,
    this.deletedAt,
  });

  Modifier copyWith({String? groupId}) {
    return Modifier(
      docId: docId,
      groupId: groupId ?? this.groupId,
      isDefault: isDefault,
      label: label,
      priceDelta: priceDelta,
      order: order,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
    );
  }

  factory Modifier.fromJson(Map<String, dynamic> json) => _$ModifierFromJson(json);
  Map<String, dynamic> toJson() => _$ModifierToJson(this);
}
