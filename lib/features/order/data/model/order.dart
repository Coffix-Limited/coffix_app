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
  final String? orderNumber;
  final List<Item>? items;
  final OrderStatus? status;
  final PaymentStatus? paymentStatus;
  final String? paymentMethod;
  
  Order({
    this.docId,
    this.customerId,
    this.storeId,
    this.amount,
    this.createdAt,
    this.scheduledAt,
    this.orderNumber,
    this.status,
    this.paymentStatus,
    this.items,
    this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Item {
  final String? productId;
  final int? quantity;
  final Map<String, String>? selectedModifiers;

  Item({this.productId, this.quantity, this.selectedModifiers});

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
