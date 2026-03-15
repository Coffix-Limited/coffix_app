import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/features/auth/data/model/user.dart';
import 'package:coffix_app/features/auth/data/model/user_with_store.dart';
import 'package:coffix_app/features/products/data/model/product_override.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreRepositoryImpl implements StoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _authRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StoreRepositoryImpl({required AuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Stream<List<Store>> getStores() {
    return _firestore.collection('stores').snapshots().map((event) {
      return event.docs.map((doc) => Store.fromJson(doc.data())).toList();
    });
  }

  @override
  Stream<Store> getPreferredStore({required String storeId}) {
    return _firestore.collection('stores').doc(storeId).snapshots().map((
      event,
    ) {
      return event.exists
          ? Store.fromJson(event.data() ?? {})
          : throw Exception('Store not found');
    });
  }

  @override
  Stream<AppUserWithStore?> getUserWithStore() {
    final userStream = _authRepository.getUser();
    return userStream.switchMap((user) {
      final String? storeId = user?.preferredStoreId;
      if (storeId == null || storeId.isEmpty) {
        return Stream.value(AppUserWithStore(user: user!, store: null));
      }

      return Rx.combineLatest2<AppUser, Store, AppUserWithStore>(
        Stream.value(user!),
        getPreferredStore(storeId: storeId),
        (user, stores) {
          return AppUserWithStore(user: user, store: stores);
        },
      );
    });
  }

  /// Get the product override for a given product and store.
  /// If the product override does not exist, treat as empty override
  @override
  Future<ProductOverride> getProductOverride({
    required String productId,
    required String storeId,
  }) async {
    final overrideSnap = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection("productOverrides")
        .doc(productId)
        .get();

    final override = overrideSnap.exists
        ? ProductOverride.fromJson(overrideSnap.data() ?? {})
        : ProductOverride(disabledGroupIds: [], disabledModifierIds: []);

    return override;
  }

  @override
  Future<void> updatePreferredStore({required String storeId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not found');
    }
    final storeRef = _firestore.collection('customers').doc(user.uid);
    await storeRef.set({
      'preferredStoreId': storeId,
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> openMap(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open the map";
    }
  }
}
