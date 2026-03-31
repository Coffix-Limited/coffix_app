import 'dart:async';

import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

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
  StreamSubscription<User?>? _authSubscription;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initWrapper();
    });
  }

  void initWrapper() async {
    context.read<AppCubit>().getGlobal();
  }

  @override
  Widget build(BuildContext context) {
    final appVersion = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global, appVersion) => appVersion,
      orElse: () => null,
    );
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
  }
}
