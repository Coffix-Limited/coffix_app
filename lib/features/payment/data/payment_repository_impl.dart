
import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/data/repositories/payment_repository.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentRepositoryImpl extends ApiClient implements PaymentRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  PaymentRepositoryImpl() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> createPaymentSession({
    required PaymentRequest request,
  }) async {
    final response = await post("/payment/session", data: request.toJson());

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<String> topupCredit({required double amount}) async {
    final response = await post("/credit/topup", data: {'amount': amount});

    final paymentSessionUrl = response.data['paymentSessionUrl'] as String?;
    if (paymentSessionUrl == null || paymentSessionUrl.isEmpty) {
      throw Exception('No paymentSessionUrl in response');
    }
    return paymentSessionUrl;
  }
}
