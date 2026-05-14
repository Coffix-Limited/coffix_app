import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.g.dart';

enum OrderStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('pending_payment')
  pendingPayment,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('preparing')
  preparing,
  @JsonValue('ready')
  ready,
  @JsonValue('paid')
  paid,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('pending')
  pending,
  @JsonValue('payment_failed')
  paymentFailed,
}

@JsonSerializable(explicitToJson: true)
class Order {
  final String? docId;
  final String? customerId;
  final String? storeId;
  final double? amount;
  @DateTimeConverter()
  final DateTime? createdAt;
  @DateTimeConverter()
  final DateTime? scheduledAt;
  final List<Item>? items;
  @JsonKey(unknownEnumValue: OrderStatus.draft)
  final OrderStatus? status;
  final PaymentStatus? paymentStatus;
  @PaymentMethodConverter()
  final PaymentMethod? paymentMethod;
  final String? storeName;
  String? transactionNumber;

  Order({
    this.docId,
    this.customerId,
    this.storeId,
    this.amount,
    this.createdAt,
    this.scheduledAt,
    this.status,
    this.paymentStatus,
    this.items,
    this.paymentMethod,
    this.storeName,
    this.transactionNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Item {
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final double? price;
  final double? basePrice;
  final int? quantity;
  final Map<String, String>? selectedModifiers;
  final List<ItemModifier>? modifiers;

  Item({
    this.productId,
    this.productName,
    this.productImageUrl,
    this.price,
    this.basePrice,
    this.quantity,
    this.selectedModifiers,
    this.modifiers,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ItemModifier {
  final String? modifierId;
  final double? priceDelta;
  final String? name;

  ItemModifier({this.modifierId, this.priceDelta, this.name});

  factory ItemModifier.fromJson(Map<String, dynamic> json) =>
      _$ItemModifierFromJson(json);
  Map<String, dynamic> toJson() => _$ItemModifierToJson(this);
}
