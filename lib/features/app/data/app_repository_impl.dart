import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/constants/constants.dart';
import 'package:coffix_app/data/repositories/app_repository.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/app/data/model/global.dart';
import 'package:firebase_core/firebase_core.dart';

class AppRepositoryImpl implements AppRepository {
  final FirebaseFirestore _firestore = FirestoreService.instance;

  @override
  Future<AppGlobal> getGlobal() async {
    try {
      final snapshot = await _firestore
          .collection('global')
          .doc('EQ0i4V6H47Ra7yMCdG7B')
          .get();
      return AppGlobal.fromJson(snapshot.data() ?? {});
    } catch (_) {
      return const AppGlobal();
    }
  }
}
