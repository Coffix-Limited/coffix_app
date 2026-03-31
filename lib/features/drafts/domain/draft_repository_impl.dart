import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/domain/draft_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DraftRepositoryImpl implements DraftRepository {
  final FirebaseFirestore _firestore = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DraftRepositoryImpl();

  @override
  Future<void> createDraft({required Cart cart}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not found');
    }
    final draftRef = _firestore.collection('drafts').doc();
    await draftRef.set({
      'id': draftRef.id,
      'userId': userId,
      'cart': cart.toJson(),
      'createdAt': TimeUtils.now(),
      'updatedAt': TimeUtils.now(),
    });
  }

  @override
  Stream<List<Draft>> getDrafts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not found');
    }
    try {
      final snapshot = _firestore
          .collection('drafts')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((event) {
            return event.docs.map((doc) {
              return Draft.fromJson(doc.data());
            }).toList();
          });
          return snapshot;
    } catch (e) {
      print("error: $e");
      throw Exception('Failed to get drafts');
    }
  }

  @override
  Future<void> deleteDraft({required String draftId}) async {
    await _firestore.collection('drafts').doc(draftId).delete();
  }
}
