import 'dart:convert';
import 'dart:developer';

import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/core/api/model/endpoints.dart';
import 'package:coffix_app/data/repositories/payment_repository.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('${ApiEndpoints.v1}/credit/topup'),
      body: jsonEncode({'amount': amount}),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>?;
    final paymentSessionUrl = data?['data']?['paymentSessionUrl'] as String?;
    if (paymentSessionUrl == null || paymentSessionUrl.isEmpty) {
      throw Exception(
        'No paymentSessionUrl in response (${response.statusCode}): ${response.body}',
      );
    }
    return paymentSessionUrl;
  }
}
