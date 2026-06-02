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
  final String? severityLevel;
  // used for admin controlling staff not customers in web app
  final String? userId;

  /// (purchase, gift, topup, referral, draft, credit, invoice request, login etc)
  final String? action;

  /// English description with reference (order number etc)
  final String? notes;
  @DateTimeConverter()
  final DateTime? time;

  //   •⁠ ⁠action: (purchase, gift, topup, referral, draft, credit, invoice request, login etc)
  // •⁠ ⁠category: (Apperror, WebError, App, Web etc)
  // •⁠ ⁠⁠page ( the reference to the page action taken)
  // •⁠ ⁠⁠notes: English description with reference (order number etc)
  // •⁠ ⁠⁠security level: categorise them by importance for long term. 1 will be the lowest so will be deleted more often (like login, password recovery etc). 5- mid level such as errors, payment decline etc). 9 - will be kept long term (financial transactions etc)
  // •⁠ ⁠⁠time: timestamp

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
