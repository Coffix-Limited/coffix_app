import 'package:coffix_app/features/auth/data/model/user_with_store.dart';
import 'package:coffix_app/features/products/data/model/product_override.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';

abstract class StoreRepository {
  Stream<List<Store>> getStores();
  Stream<Store> getPreferredStore({required String storeId});
  Stream<AppUserWithStore?> getUserWithStore();
  Future<ProductOverride> getProductOverride({
    required String productId,
    required String storeId,
  });
  Future<void> updatePreferredStore({required String storeId});
  Future<void> openMap(double lat, double lng);
}
