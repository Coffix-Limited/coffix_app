import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.g.dart';

class PaymentMethodConverter implements JsonConverter<PaymentMethod?, dynamic> {
  const PaymentMethodConverter();

  @override
  PaymentMethod? fromJson(dynamic json) {
    if (json == null || json == '') return PaymentMethod.card;
    final s = json is String ? json : json.toString();
    switch (s) {
      case 'coffixCredit':
        return PaymentMethod.coffixCredit;
      case 'card':
        return PaymentMethod.card;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.card;
    }
  }

  @override
  String? toJson(PaymentMethod? object) =>
      object != null ? _$PaymentMethodEnumMap[object] : null;
}

enum PaymentMethod {
  @JsonValue("coffixCredit")
  coffixCredit,
  @JsonValue("card")
  card,
  @JsonValue("cash")
  cash,
}

enum PaymentStatus {
  @JsonValue('unpaid')
  unpaid,
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
}

@JsonSerializable(explicitToJson: true)
class PaymentRequest {
  final String storeId;
  final List<PaymentItem> items;
  @DateTimeConverter()
  final double duration;
  @JsonKey(defaultValue: PaymentMethod.card)
  final PaymentMethod? paymentMethod;

  PaymentRequest({
    required this.storeId,
    required this.items,
    required this.duration,
    required this.paymentMethod,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentRequestToJson(this);
}

@JsonSerializable()
class PaymentItem {
  final String productId;
  final int quantity;
  final Map<String, String> selectedModifiers;

  PaymentItem({
    required this.productId,
    required this.quantity,
    required this.selectedModifiers,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) =>
      _$PaymentItemFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentItemToJson(this);
}

// {
//     "storeId": "atdqdUXR8HQjRyBUJjEx",
//     "items": [
//         {
//             "productId": "7yWKEn9eeRTbW3ArLEeZ",
//             "quantity": 5,
//             "selectedModifiers": {}
//         }
//     ]
// }
