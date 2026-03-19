import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/data/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  }) async {}
}
