import 'dart:ffi';

import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/about_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/personal_info_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/qr_id_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/share_your_balance_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/special_url_page.dart';
import 'package:coffix_app/features/profile/presentation/widgets/profile_tile.dart';
import 'package:coffix_app/features/transaction/presentation/pages/transaction_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  static String route = 'profile_route';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double creditBalance = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) =>
          double.parse(user.user.creditAvailable?.toString() ?? '0.00'),
      orElse: () => 0,
    );
    return Scaffold(
      appBar: AppBackHeader(title: "My Account"),
      body: SingleChildScrollView(
        padding: AppSizes.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Credit balance',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text.rich(
                    creditBalance.toCurrencySuperscript(
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppButton.primary(
                    onPressed: () {
                      context.goNamed(CreditPage.route);
                    },
                    label: 'Top up',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            Text(
              'Account',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.lightGrey,
              ),
            ),
            ProfileTile(
              label: 'Profile',
              onTap: () {
                context.pushNamed(PersonalInfoPage.route);
              },
              icon: AppImages.profile,
            ),
            const SizedBox(height: AppSizes.sm),

            Text(
              'Wallet',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.lightGrey,
              ),
            ),
            ProfileTile(
              label: 'Transaction history',
              onTap: () {
                context.pushNamed(TransactionPage.route);
              },
              icon: AppImages.transaction,
            ),
            ProfileTile(
              label: 'Share your balance',
              onTap: () {
                context.pushNamed(ShareYourBalancePage.route);
              },
              icon: AppImages.balance,
            ),
            ProfileTile(
              label: 'Specials',
              onTap: () {
                context.pushNamed(SpecialUrlPage.route);
              },
              icon: AppImages.special,
            ),
            ProfileTile(
              label: 'Coffix QR ID',
              onTap: () {
                context.pushNamed(QrIdPage.route);
              },
              icon: AppImages.id,
            ),
            ProfileTile(
              label: 'Coffee on us',
              onTap: () {},
              icon: AppImages.coffee,
            ),
            ProfileTile(
              label: 'Coffee for home',
              onTap: () {},
              icon: AppImages.bag,
            ),
            const SizedBox(height: AppSizes.sm),

            Text(
              'About Coffix',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.lightGrey,
              ),
            ),
            ProfileTile(
              label: 'About',
              onTap: () {
                context.pushNamed(AboutPage.route);
              },
              icon: AppImages.info,
            ),
            ProfileTile(
              label: 'Logout',
              onTap: () {
                context.read<AuthCubit>().signOut();
              },
              icon: AppImages.logout,
            ),
            const SizedBox(height: AppSizes.xxxl),
            Center(
              child: AppClickable(
                onPressed: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  child: Text(
                    'Terms of use & privacy',
                    style: AppTypography.bodyXS.copyWith(
                      color: AppColors.lightGrey,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.lightGrey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}
