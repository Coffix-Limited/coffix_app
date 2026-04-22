import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GuestHomeContent extends StatelessWidget {
  const GuestHomeContent({
    super.key,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: AppSizes.defaultPadding,
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: screenHeight * 0.05),
          Text(
            'Browse our menu or sign in to order.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: AppColors.black,
            ),
          ),
          SizedBox(height: screenHeight * 0.05),
          AppButton.primary(
            label: 'Browse Menu',
            onPressed: () {
              context.read<ProductCubit>().initDefaultCategory();
              context.goNamed(MenuPage.route);
            },
          ),
          const SizedBox(height: AppSizes.xl),
          AppButton.primary(
            label: 'Sign In',
            onPressed: onSignIn,
          ),
          const SizedBox(height: AppSizes.md),
          AppButton.outlined(
            label: 'Create Account',
            onPressed: onCreateAccount,
          ),
          SizedBox(height: screenHeight * 0.05),
        ],
      ),
    );
  }
}
