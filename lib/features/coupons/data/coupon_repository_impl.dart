import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/data/repositories/coupon_repository.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/coupons/data/model/coupon.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CouponRepositoryImpl implements CouponRepository {
  final FirebaseFirestore _firestore = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<List<Coupon>> streamCoupons() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not found');
    }
    return _firestore
        .collection('coupons')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => Coupon.fromJson({...doc.data(), 'docId': doc.id}))
              .where((coupon) => _isEligible(coupon, now))
              .toList();
        });
  }

  bool _isEligible(Coupon coupon, DateTime now) {
    final notExpired = coupon.expiryDate == null || coupon.expiryDate!.isAfter(now);
    final hasBalance = coupon.remainingAmount == null || coupon.remainingAmount! > 0;
    return notExpired && hasBalance;
  }
}
