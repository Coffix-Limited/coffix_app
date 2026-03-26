import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/constants/constants.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/domain/draft_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
  Future<List<Draft>> getDrafts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not found');
    }
    try {
      final snapshot = await _firestore
          .collection('drafts')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) {
        return Draft.fromJson(doc.data());
      }).toList();
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
