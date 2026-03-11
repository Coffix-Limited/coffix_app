import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/presentation/pages/verify_email_page.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/modifier/logic/modifier_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum LayoutPageTab {
  home(
    title: "Home",
    icon: AppImages.homeFilled,
    selectedIcon: AppImages.homeFilled,
  ),
  coffixCredit(
    title: "Coffix Credit",
    icon: AppImages.credit,
    selectedIcon: AppImages.credit,
  ),
  menu(title: "Menu", icon: AppImages.coffee, selectedIcon: AppImages.coffee),
  stores(title: "Stores", icon: AppImages.shop, selectedIcon: AppImages.shop),
  order(title: "My Order", icon: AppImages.cart, selectedIcon: AppImages.cart);

  final String title;
  final String icon;
  final String selectedIcon;

  const LayoutPageTab({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
}

class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AppCubit>()),
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<StoreCubit>()),
        BlocProvider.value(value: getIt<ProductCubit>()),
        BlocProvider.value(value: getIt<ModifierCubit>()),
      ],
      child: LayoutView(shell: shell),
    );
  }
}

class LayoutView extends StatefulWidget {
  const LayoutView({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<LayoutView> createState() => _LayoutViewState();
}

class _LayoutViewState extends State<LayoutView> {
  @override
  initState() {
    super.initState();
    // context.read<AppCubit>().getGlobal();
    // context.read<AuthCubit>().getUserWithStore();
    // context.read<StoreCubit>().getStores();
    // context.read<ProductCubit>().getProducts();
    // context.read<ModifierCubit>().getModifiers();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user.user,
      orElse: () => null,
    );
    final isEmailVerified = user?.emailVerified ?? false;

    const topLevelTabPaths = [
      '/home',
      '/coffix-credit',
      '/menu',
      '/stores',
      '/cart',
    ];
    // final isOnHomeBranchNested =
    //     widget.shell.currentIndex == 0 && location != '/home';
    // final showBottomNav =
    //     isEmailVerified &&
    //     !isOnHomeBranchNested &&
    //     topLevelTabPaths.contains(location);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Get the current tab index
          final currentIndex = widget.shell.currentIndex;

          // If we're not on the home tab (index 0), go back to home
          if (currentIndex != 0) {
            widget.shell.goBranch(0);
          }
        }
      },
      child: Scaffold(
        body: widget.shell,
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            bottomAppBarTheme: const BottomAppBarThemeData(
              shadowColor: Colors.transparent,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              enableFeedback: false,
            ),
          ),
          child: SizedBox(
            child: BottomNavigationBar(
              currentIndex: widget.shell.currentIndex,
              onTap: (index) {
                widget.shell.goBranch(index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedLabelStyle: AppTypography.body2XS.copyWith(
                color: AppColors.textBlackColor,
              ),
              unselectedLabelStyle: AppTypography.body2XS.copyWith(
                color: AppColors.textBlackColor,
              ),
              items: LayoutPageTab.values.map((tab) {
                final orderCount =
                    context.watch<CartCubit>().state.cart?.items.length ?? 0;
                return BottomNavigationBarItem(
                  icon: tab == LayoutPageTab.order
                      ? Badge.count(
                          count: orderCount,
                          child: AppIcon.withSvgPath(
                            tab.icon,
                            // color:
                            //     widget.shell.currentIndex ==
                            //         LayoutPageTab.values.indexOf(tab)
                            //     ? AppColors.primary
                            //     : AppColors.lightGrey,
                          ),
                        )
                      : AppIcon.withSvgPath(
                          tab.icon,
                          // color:
                          //     widget.shell.currentIndex ==
                          //         LayoutPageTab.values.indexOf(tab)
                          //     ? AppColors.primary
                          //     : AppColors.lightGrey,
                        ),
                  label: tab.title,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
