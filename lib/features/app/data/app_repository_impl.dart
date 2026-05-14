import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/constants/constants.dart';
import 'package:coffix_app/data/repositories/app_repository.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/app/data/model/global.dart';

class AppRepositoryImpl implements AppRepository {
  final FirebaseFirestore _firestore = FirestoreService.instance;

  @override
  Stream<AppGlobal> getGlobal() {
    return _firestore
        .collection('global')
        .doc(AppConstants.globalCollectionDocId)
        .snapshots()
        .map((snapshot) => AppGlobal.fromJson(snapshot.data() ?? {}));
  }
}
