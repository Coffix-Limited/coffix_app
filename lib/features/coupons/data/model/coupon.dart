import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon.g.dart';

@JsonSerializable()
class Coupon {
  final String? docId;
  final double? amount;
  @DateTimeConverter()
  DateTime? createdAt;
  final String? customerEmail;
  @DateTimeConverter()
  DateTime? expiryDate;
  final String? storeId;
  final String? type; // admin | referral
  final String? notes;
  final String? userId;

  Coupon({
    this.docId,
    this.amount,
    this.createdAt,
    this.customerEmail,
    this.expiryDate,
    this.storeId,
    this.type,
    this.notes,
    this.userId,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);
  Map<String, dynamic> toJson() => _$CouponToJson(this);
}
