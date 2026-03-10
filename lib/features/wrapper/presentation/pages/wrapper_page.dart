import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/presentation/pages/verify_email_page.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class WrapperPage extends StatelessWidget {
  static String route = 'wrapper_route';
  const WrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<AppCubit>()),
        BlocProvider.value(value: getIt<StoreCubit>()),
        BlocProvider.value(value: getIt<ProductCubit>()),
      ],
      child: const WrapperView(),
    );
  }
}

class WrapperView extends StatefulWidget {
  const WrapperView({super.key});

  @override
  State<WrapperView> createState() => _WrapperViewState();
}

class _WrapperViewState extends State<WrapperView> {
  @override
  void initState() {
    super.initState();
    initWrapper();
  }

  void initWrapper() async {
    context.read<AppCubit>().getGlobal();
    context.read<AuthCubit>().getUserWithStore();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (user) {
            context.read<StoreCubit>().getStores();
            context.read<ProductCubit>().getProducts();
            if (user.user.emailVerified != true) {
              context.goNamed(
                VerifyEmailPage.route,
                extra: {'email': user.user.email},
              );
            } else if (user.user.disabled == true) {
              // AppSnackbar.showError(context, "Your account has been disabled");
            } else {
              context.goNamed(HomePage.route);
            }
          },
        );
      },
      builder: (context, state) {
        state.whenOrNull(loading: () => AppLoading());
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.black,
            title: AppIcon.withSvgPath(AppImages.nameLogo, size: 180),
          ),
          backgroundColor: AppColors.black,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Coffix App",
                textAlign: TextAlign.center,
                style: AppTypography.titleXL.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: AppSizes.xl),
              SvgPicture.asset(AppImages.logo, width: 256, height: 256),
            ],
          ),
        );
      },
    );
  }
}
