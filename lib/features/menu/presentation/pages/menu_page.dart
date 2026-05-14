import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/product_extensions.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/products/logic/product_modifier_cubit.dart';
import 'package:coffix_app/features/products/presentation/widgets/product_list.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    final firstStoreId = context.watch<StoreCubit>().state.maybeWhen(
      loaded: (stores) => stores.isNotEmpty ? stores.first.docId : '',
      orElse: () => '',
    );
    final storeId = user?.user.preferredStoreId ?? firstStoreId;
    return Scaffold(
      appBar: AppBackHeader(
        title: "Products",
        onBack: () {
          context.goNamed(HomePage.route);
        },
      ),
      // floatingActionButton: AppCart(),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => AppLoading(),
            loaded: (products, allCategories, categoryFilter) => ProductList(
              products: products.productsByStore(
                storeId: storeId,
                preferredStoreId: storeId,
              ),
              allCategories: allCategories.sorted(
                (a, b) => (a.order?.compareTo(b.order ?? "0") ?? 0).toInt(),
              ),
              isRoot: true,
              categoryFilter: categoryFilter,
              storeId: storeId,
            ),
            error: (message) =>
                AppError(title: "Failed getting products", subtitle: message),
          );
        },
      ),
    );
  }
}
