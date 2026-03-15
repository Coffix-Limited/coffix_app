part of 'product_cubit.dart';

@freezed
class ProductState with _$ProductState {
  const factory ProductState.initial() = _Initial;
  const factory ProductState.loading() = _Loading;
  const factory ProductState.loaded({
    required List<ProductWithCategory> products,
    @Default([]) List<ProductCategory> allCategories,
    @Default(null) String? categoryFilter,
  }) = _Loaded;
  const factory ProductState.error({required String message}) = _Error;
}
