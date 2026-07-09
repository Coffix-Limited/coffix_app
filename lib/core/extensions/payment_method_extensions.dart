import 'package:coffix_app/features/payment/data/model/payment.dart';

extension PaymentMethodExtensions on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return 'Credit Card';
      case PaymentMethod.coffixCredit:
        return 'Coffix Credit';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}
