import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/data/repositories/payment_repository.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:dio/dio.dart';

class PaymentRepositoryImpl extends ApiClient implements PaymentRepository {
  PaymentRepositoryImpl() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> createPaymentSession({
    required PaymentRequest request,
  }) async {
    final response = await post("/payment/session", data: request.toJson());

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> topupCredit({required double amount}) async {
    final response = await post("/credit/topup", data: {'amount': amount});

    final data = response.data as Map<String, dynamic>;
    final paymentSessionUrl = data['paymentSessionUrl'] as String?;
    if (paymentSessionUrl == null || paymentSessionUrl.isEmpty) {
      throw Exception('No paymentSessionUrl in response');
    }
    final transaction = data['transaction'] as Map<String, dynamic>?;
    return {
      'paymentSessionUrl': paymentSessionUrl,
      'amount': (transaction?['amount'] as num?)?.toDouble() ?? 0.0,
      'transactionNumber': transaction?['transactionNumber'] as String? ?? '',
    };
  }
}
