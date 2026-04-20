import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/product_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/products/data/model/product_category.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:coffix_app/features/modifier/logic/modifier_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/products/logic/product_modifier_cubit.dart';
import 'package:coffix_app/features/products/presentation/widgets/product_list.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:coffix_app/features/stores/presentation/pages/stores_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductsPage extends StatelessWidget {
  static String route = 'products_route';
  const ProductsPage({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ProductCubit>()),
        BlocProvider.value(value: getIt<ModifierCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<ProductModifierCubit>()),
      ],
      child: ProductView(storeId: storeId),
    );
  }
}

class ProductView extends StatefulWidget {
  const ProductView({super.key, required this.storeId});

  final String storeId;

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final store = authState.maybeWhen(
      authenticated: (user) => user.store,
      orElse: () => null,
    );
    final preferredStoreId = authState.maybeWhen(
      authenticated: (userWithStore) => userWithStore.user.preferredStoreId,
      orElse: () => null,
    );
    final isClosed = store != null && !store.isOpenAt();

    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              return state.when(
                initial: () => const SizedBox.shrink(),
                loading: () => AppLoading(),
                loaded:
                    (
                      List<ProductWithCategory> products,
                      List<ProductCategory> allCategories,
                      String? categoryFilter,
                    ) => ProductList(
                      products: products
                          .productsByStore(
                            storeId: widget.storeId,
                            preferredStoreId: preferredStoreId ?? "",
                          )
                          .toList(),
                      allCategories: allCategories,
                      categoryFilter: categoryFilter,
                      storeId: widget.storeId,
                    ),
                error: (message) => AppError(
                  title: "Failed getting products",
                  subtitle: message,
                ),
              );
            },
          ),
          if (isClosed) _ClosedOverlay(store: store),
        ],
      ),
    );
  }
}

class _ClosedOverlay extends StatelessWidget {
  const _ClosedOverlay({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final next = store.nextOpeningFormatted();

    return Container(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, size: 64, color: AppColors.lightGrey),
              const SizedBox(height: AppSizes.md),
              Text(
                'Store is currently closed',
                style: AppTypography.titleL,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              if (next != null)
                Text(
                  'Opens ${next.day} at ${next.time}',
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.lightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppSizes.lg),
              AppButton.primary(
                label: 'Choose another store',
                onPressed: () => context.goNamed(StoresPage.route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
