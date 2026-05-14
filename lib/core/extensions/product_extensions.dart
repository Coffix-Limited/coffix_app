import 'package:coffix_app/features/products/data/model/product_with_category.dart';

extension ProductExtensions on List<ProductWithCategory> {
  /// Returns a list of products that are available in the given store.
  List<ProductWithCategory> productsByStore({
    required String storeId,
    required String preferredStoreId,
  }) {
    return where((product) {
      final disabledStores = product.product.disabledStores;
      final availableStores = product.product.availableToStores;

      // Rule 1: If user's preferred store is disabled → NEVER show
      if (disabledStores != null && disabledStores.contains(preferredStoreId)) {
        return false;
      }

      // Rule 2: If availableStores is null → available everywhere
      if (availableStores == null) {
        return true;
      }

      // Rule 3: Otherwise must be explicitly available in the browsed store
      return availableStores.contains(storeId);
    }).toList();
  }
}
