import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.g.dart';

enum TransactionStatus {
  @JsonValue('created')
  created,
  @JsonValue('paid')
  paid,
  @JsonValue('failed')
  failed,
  @JsonValue('approved')
  approved,
  @JsonValue('declined')
  declined,
  @JsonValue('completed')
  completed,
  @JsonValue('expired')
  expired,
  @JsonValue('sent')
  sent,
  @JsonValue('claimed')
  claimed,
}

@JsonSerializable()
class Transaction {
  final String? docId;
  final String? orderId;
  final String? customerId;
  final double? amount;
  @DateTimeConverter()
  final DateTime? createdAt;
  @JsonKey(unknownEnumValue: TransactionStatus.created)
  final TransactionStatus? status;
  @PaymentMethodConverter()
  final PaymentMethod? paymentMethod;
  final String? paymentId;
  @DateTimeConverter()
  final DateTime? paymentTime;
  final String? orderNumber;
  final String? type;
  String? recipientCustomerId;
  String? recipientEmail;
  String? recipientFullName;
  String? senderFullName;
  String? senderEmail;
  String? transactionNumber;
  double? totalAmount;
  double? gst;
  double? gstAmount;
  String? gstNumber;

  Transaction({
    this.docId,
    this.orderId,
    this.customerId,
    this.amount,
    this.createdAt,
    this.status,
    this.paymentMethod,
    this.paymentId,
    this.paymentTime,
    this.orderNumber,
    this.type,
    this.recipientCustomerId,
    this.recipientEmail,
    this.recipientFullName,
    this.senderFullName,
    this.senderEmail,
    this.transactionNumber,
    this.totalAmount,
    this.gst,
    this.gstAmount,
    this.gstNumber,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}
