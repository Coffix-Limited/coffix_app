import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'log.g.dart';

@JsonSerializable(explicitToJson: true)
class Log {
  final String? docId;
  final String? page;
  final String? customerId;

  /// AppError, WebError, App, Web etc.
  final String? category;

  /// [1] - low level (login, forgot password etc.)
  /// [3] - mid level (errors, payment decline, etc.)
  /// [5] - high level (financial transactions etc.)
  final int? severityLevel;
  // used for admin controlling staff not customers in web app
  final String? userId;

  /// (purchase, gift, topup, referral, draft, credit, invoice request, login etc)
  final String? action;

  /// English description with reference (order number etc)
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

  Log copyWith({String? customerId}) => Log(
    docId: docId,
    page: page,
    customerId: customerId ?? this.customerId,
    category: category,
    severityLevel: severityLevel,
    userId: userId,
    action: action,
    notes: notes,
    time: time,
  );
}
