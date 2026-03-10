import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_page.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreditSuccessfulPage extends StatelessWidget {
  static String route = 'credit_successful_route';

  const CreditSuccessfulPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreditSuccessfulView();
  }
}

class CreditSuccessfulView extends StatelessWidget {
  const CreditSuccessfulView({super.key});

  @override
  Widget build(BuildContext context) {
    final creditBalance = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (u) => u.user.creditAvailable ?? 0.0,
      orElse: () => 0.0,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Column(
            children: [
              AppBackHeader(title: "Top Up Successful", showBackButton: false),
              const Spacer(),
              Icon(
                Icons.check_circle_rounded,
                size: AppSizes.iconSizeXLarge,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSizes.xxl),
              Text(
                'Credit top up successful',
                style: AppTypography.headlineXl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Your Coffix Credit balance has been updated',
                style: AppTypography.bodyM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.md),
                ),
                child: Text(
                  'Total Balance: \$${creditBalance.toStringAsFixed(2)}',
                  style: AppTypography.titleM.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              const Spacer(),
              AppButton.primary(
                onPressed: () {
                  context.goNamed(CreditPage.route);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.goNamed(HomePage.route);
                  });
                },
                label: 'Back to home',
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }
}
