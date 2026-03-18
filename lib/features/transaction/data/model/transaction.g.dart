// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  docId: json['docId'] as String?,
  orderId: json['orderId'] as String?,
  customerId: json['customerId'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  status: $enumDecodeNullable(_$TransactionStatusEnumMap, json['status']),
  paymentMethod: const PaymentMethodConverter().fromJson(json['paymentMethod']),
  paymentId: json['paymentId'] as String?,
  paymentTime: const DateTimeConverter().fromJson(json['paymentTime']),
  orderNumber: json['orderNumber'] as String?,
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'docId': instance.docId,
      'orderId': instance.orderId,
      'customerId': instance.customerId,
      'amount': instance.amount,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'status': _$TransactionStatusEnumMap[instance.status],
      'paymentMethod': const PaymentMethodConverter().toJson(
        instance.paymentMethod,
      ),
      'paymentId': instance.paymentId,
      'paymentTime': const DateTimeConverter().toJson(instance.paymentTime),
      'orderNumber': instance.orderNumber,
    };

const _$TransactionStatusEnumMap = {
  TransactionStatus.created: 'created',
  TransactionStatus.paid: 'paid',
  TransactionStatus.failed: 'failed',
  TransactionStatus.approved: 'approved',
};
