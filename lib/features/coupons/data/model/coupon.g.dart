// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Coupon _$CouponFromJson(Map<String, dynamic> json) => Coupon(
  docId: json['docId'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  customerEmail: json['customerEmail'] as String?,
  expiryDate: const DateTimeConverter().fromJson(json['expiryDate']),
  storeId: json['storeId'] as String?,
  type: json['type'] as String?,
  notes: json['notes'] as String?,
  userId: json['userId'] as String?,
  remainingAmount: (json['remainingAmount'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CouponToJson(Coupon instance) => <String, dynamic>{
  'docId': instance.docId,
  'amount': instance.amount,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'customerEmail': instance.customerEmail,
  'expiryDate': const DateTimeConverter().toJson(instance.expiryDate),
  'storeId': instance.storeId,
  'type': instance.type,
  'notes': instance.notes,
  'userId': instance.userId,
  'remainingAmount': instance.remainingAmount,
};
