import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/products/logic/product_modifier_cubit.dart';
import 'package:coffix_app/features/products/presentation/widgets/product_list.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/app_cart.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuPage extends StatelessWidget {
  static String route = 'menu_route';
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ProductModifierCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
      ],
      child: const MenuView(),
    );
  }
}

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    return Scaffold(
      appBar: AppBackHeader(title: "Products", showBackButton: false),
      // floatingActionButton: AppCart(),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => AppLoading(),
            loaded: (products, allCategories, categoryFilter) => ProductList(
              products: products,
              allCategories: allCategories,
              isRoot: true,
              categoryFilter: categoryFilter,
              storeId: user?.user.preferredStoreId ?? '',
            ),
            error: (message) =>
                AppError(title: "Failed getting products", subtitle: message),
          );
        },
      ),
    );
  }
}
