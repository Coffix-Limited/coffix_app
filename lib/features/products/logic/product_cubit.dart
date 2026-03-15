import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/product_repository.dart';
import 'package:coffix_app/features/products/data/model/product_category.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_state.dart';
part 'product_cubit.freezed.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  StreamSubscription<List<ProductWithCategory>>? _productsSubscription;
  List<ProductWithCategory> _allProducts = [];
  bool _initialized = false;

  ProductCubit({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(ProductState.initial());

  List<ProductCategory> get _categories =>
      _allProducts.map((p) => p.category).toSet().toList();

  void _initDefaultCategory() {
    if (_categories.isEmpty) return;
    final coffee = _categories.firstWhere(
      (c) => c.name?.toLowerCase() == 'coffee',
      orElse: () => _categories.first,
    );
    filterProductsByCategory(coffee.name!);
  }

  Future<void> getProducts() async {
    emit(ProductState.loading());
    _productsSubscription?.cancel();
    _initialized = false;
    try {
      _productsSubscription = _productRepository
          .getProductsWithCategories()
          .listen((products) {
            _allProducts = products;
            if (!_initialized) {
              _initialized = true;
              _initDefaultCategory();
            } else {
              emit(ProductState.loaded(
                products: products,
                allCategories: _categories,
              ));
            }
          }, onError: (e) => emit(ProductState.error(message: e.toString())));
    } catch (e) {
      emit(ProductState.error(message: e.toString()));
    }
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      emit(ProductState.loaded(
        products: List.from(_allProducts),
        allCategories: _categories,
      ));
      return;
    }
    final lower = query.toLowerCase();
    final filtered = _allProducts
        .where((p) => p.product.name?.toLowerCase().contains(lower) ?? false)
        .toList();
    emit(ProductState.loaded(products: filtered, allCategories: _categories));
  }

  void filterProductsByCategory(String category) {
    final List<ProductWithCategory> filtered = _allProducts
        .where(
          (p) =>
              p.category.name?.toLowerCase().contains(category.toLowerCase()) ??
              false,
        )
        .toList();
    emit(ProductState.loaded(
      products: filtered,
      allCategories: _categories,
      categoryFilter: category,
    ));
  }

  void clearFilter() {
    emit(ProductState.loaded(
      products: List.from(_allProducts),
      allCategories: _categories,
    ));
  }
}
