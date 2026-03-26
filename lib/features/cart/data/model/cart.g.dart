// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cart _$CartFromJson(Map<String, dynamic> json) => Cart(
  storeId: json['storeId'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  duration: (json['duration'] as num?)?.toDouble(),
  paymentMethod: $enumDecodeNullable(
    _$PaymentMethodEnumMap,
    json['paymentMethod'],
  ),
);

Map<String, dynamic> _$CartToJson(Cart instance) => <String, dynamic>{
  'storeId': instance.storeId,
  'items': instance.items?.map((e) => e.toJson()).toList(),
  'duration': instance.duration,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.coffixCredit: 'coffixCredit',
  PaymentMethod.card: 'card',
  PaymentMethod.wallet: 'wallet',
};
