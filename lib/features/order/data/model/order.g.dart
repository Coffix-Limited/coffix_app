// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  docId: json['docId'] as String?,
  customerId: json['customerId'] as String?,
  storeId: json['storeId'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  scheduledAt: const DateTimeConverter().fromJson(json['scheduledAt']),
  status: $enumDecodeNullable(
    _$OrderStatusEnumMap,
    json['status'],
    unknownValue: OrderStatus.draft,
  ),
  paymentStatus: $enumDecodeNullable(
    _$PaymentStatusEnumMap,
    json['paymentStatus'],
  ),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
      .toList(),
  paymentMethod: const PaymentMethodConverter().fromJson(json['paymentMethod']),
  storeName: json['storeName'] as String?,
  transactionNumber: json['transactionNumber'] as String?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'docId': instance.docId,
  'customerId': instance.customerId,
  'storeId': instance.storeId,
  'amount': instance.amount,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'scheduledAt': const DateTimeConverter().toJson(instance.scheduledAt),
  'items': instance.items?.map((e) => e.toJson()).toList(),
  'status': _$OrderStatusEnumMap[instance.status],
  'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus],
  'paymentMethod': const PaymentMethodConverter().toJson(
    instance.paymentMethod,
  ),
  'storeName': instance.storeName,
  'transactionNumber': instance.transactionNumber,
};

const _$OrderStatusEnumMap = {
  OrderStatus.draft: 'draft',
  OrderStatus.pendingPayment: 'pending_payment',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready: 'ready',
  OrderStatus.paid: 'paid',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.pending: 'pending',
  OrderStatus.paymentFailed: 'payment_failed',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.unpaid: 'unpaid',
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
};

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  productId: json['productId'] as String?,
  productName: json['productName'] as String?,
  productImageUrl: json['productImageUrl'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  basePrice: (json['basePrice'] as num?)?.toDouble(),
  quantity: (json['quantity'] as num?)?.toInt(),
  selectedModifiers: (json['selectedModifiers'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  modifiers: (json['modifiers'] as List<dynamic>?)
      ?.map((e) => ItemModifier.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'productId': instance.productId,
  'productName': instance.productName,
  'productImageUrl': instance.productImageUrl,
  'price': instance.price,
  'basePrice': instance.basePrice,
  'quantity': instance.quantity,
  'selectedModifiers': instance.selectedModifiers,
  'modifiers': instance.modifiers?.map((e) => e.toJson()).toList(),
};

ItemModifier _$ItemModifierFromJson(Map<String, dynamic> json) => ItemModifier(
  modifierId: json['modifierId'] as String?,
  priceDelta: (json['priceDelta'] as num?)?.toDouble(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$ItemModifierToJson(ItemModifier instance) =>
    <String, dynamic>{
      'modifierId': instance.modifierId,
      'priceDelta': instance.priceDelta,
      'name': instance.name,
    };
