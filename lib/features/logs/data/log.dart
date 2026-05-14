import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'log.g.dart';

@JsonSerializable(explicitToJson: true)
class Log {
  final String? docId;
  final String? page;
  final String? customerId;
  final String? category; // refund, purchase, referral, info update, bonus,
  final String? severityLevel; // error, warning, info, success
  // used for admin controlling staff not customers in web app
  final String? userId;
  final String? action;
  final String? notes;
  @DateTimeConverter()
  final DateTime? time;

  Log({
    this.docId,
    this.page,
    this.customerId,
    this.category,
    this.severityLevel,
    this.userId,
    this.action,
    this.notes,
    this.time,
  });

  factory Log.fromJson(Map<String, dynamic> json) => _$LogFromJson(json);
  Map<String, dynamic> toJson() => _$LogToJson(this);
}
