import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/data/repositories/profile_repository.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepositoryImpl extends ApiClient implements ProfileRepository {
  final FirebaseFirestore _firestore = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileRepositoryImpl() : super(dio: Dio());

  @override
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? nickName,
    String? mobile,
    DateTime? birthday,
    String? suburb,
    String? city,
    String? preferredStoreId,
    bool? allowNotifications, // Receive notifications
    bool? getPromotions, // Receive news and promotions
    bool? getPurchaseInfoByMail, // Receive purchase messages
    bool? allowWithdrawBalance,
  }) async {
    try {
      final customerRef = _firestore
          .collection('customers')
          .doc(_auth.currentUser?.uid);

      final customerDoc = await customerRef.get();

      if (customerDoc.exists) {
        final data = <String, dynamic>{
          'firstName': ?firstName,
          'lastName': ?lastName,
          'nickName': ?nickName,
          'mobile': ?mobile,
          'birthday': ?birthday,
          'suburb': ?suburb,
          'city': ?city,
          'preferredStoreId': ?preferredStoreId,
          'finishedOnboarding': true,
          'allowNotifications': allowNotifications,
          'getPromotions': getPromotions,
          'getPurchaseInfoByMail': getPurchaseInfoByMail,
          'allowWithdrawBalance': allowWithdrawBalance,
        };
        if (data.isNotEmpty) await customerRef.update(data);
      } else {
        throw Exception('Customer not found');
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> sendCoffeeOnUs({
    required List<Map<String, dynamic>> datas,
  }) async {
    // implement the referral in here
  }

  @override
  Future<void> sendGift({
    required String recipientFirstName,
    required String recipientLastName,
    required String recipientEmail,
    required double amount,
  }) async {
    await post(
      '/credit/share',
      data: {
        'recipientFirstName': recipientFirstName,
        'recipientLastName': recipientLastName,
        'recipientEmail': recipientEmail,
        'amount': amount,
      },
    );
  }
}
