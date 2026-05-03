import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/coupons/data/model/coupon.dart';
import 'package:coffix_app/features/coupons/logic/coupon_cubit.dart';
import 'package:coffix_app/features/credit/logic/credit_cubit.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/about_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/coffee_for_home_page.dart';
import 'package:coffix_app/features/referral/pages/view/coffee_on_us_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/personal_info_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/qr_id_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/share_your_balance_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/special_url_page.dart';
import 'package:coffix_app/features/profile/presentation/widgets/profile_tile.dart';
import 'package:coffix_app/features/transaction/domain/usecases/download_transaction.dart';
import 'package:coffix_app/features/transaction/presentation/pages/transaction_page.dart';
import 'package:coffix_app/domain/usecases/use_case.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<AppCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<CreditCubit>()),
        BlocProvider.value(value: getIt<CouponCubit>()),
      ],
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CouponCubit>().streamCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double creditBalance = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) =>
          double.parse(user.user.creditAvailable?.toString() ?? '0.00'),
      orElse: () => 0,
    );
    final user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user.user,
      orElse: () => null,
    );
    final isAuthenticated = (context.read<AuthCubit>().state).maybeWhen(
      authenticated: (user) => true,
      orElse: () => false,
    );
    final global = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global, appVersion) => global,
      orElse: () => null,
    );
    final fullName = "${user?.firstName} ${user?.lastName}".length > 20
        ? "${"${user?.firstName} ${user?.lastName}".substring(0, 20)}..."
        : "${user?.firstName} ${user?.lastName}";

    return Scaffold(
      appBar: AppBackHeader(title: isAuthenticated ? fullName : "My Account"),
      body: SingleChildScrollView(
        padding: AppSizes.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "My Coffix Credit Balance",
              style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            AppCard(
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BlocBuilder<CouponCubit, CouponState>(
                    builder: (context, couponState) {
                      final coupons = couponState.maybeWhen(
                        loaded: (coupons) => coupons,
                        orElse: () => <Coupon>[],
                      );
                      final totalCoupon = coupons.fold(
                        0.0,
                        (sum, c) => sum + (c.amount ?? 0.0),
                      );
                      return Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          children: [
                            creditBalance.toCurrencySuperscript(
                              style: AppTypography.headlineXl,
                            ),
                            if (totalCoupon > 0) ...[
                              TextSpan(
                                text: " + ",
                                style: AppTypography.headlineXl,
                              ),
                              totalCoupon.toCurrencySuperscript(
                                style: AppTypography.headlineXl,
                              ),
                              TextSpan(
                                text: " Coupon",
                                style: AppTypography.bodyXS,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppButton.primary(
                    onPressed: () {
                      context.read<CreditCubit>().showTopUpField(false);
                      context.goNamed(CreditPage.route);
                    },
                    label: 'TopUp',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xxl),

            ProfileTile(
              label: 'Profile',
              onTap: () {
                context.pushNamed(PersonalInfoPage.route);
              },
              icon: AppImages.profileBlack,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),
            const SizedBox(height: AppSizes.sm),
            ProfileTile(
              label: 'Transaction history',
              onTap: () {
                context.pushNamed(TransactionPage.route);
              },
              icon: AppImages.transaction,
              trailingIcon: AppClickable(
                onPressed: () async {
                  await getIt<DownloadTransaction>().call(const NoParams());
                },
                showSplash: false,
                child: Image.asset(
                  AppImages.transactionDownload,
                  width: AppSizes.iconSizeMedium,
                  height: AppSizes.iconSizeMedium,
                ),
              ),
            ),
            Divider(height: 0, color: AppColors.textBlackColor),

            ProfileTile(
              label: 'Share your balance',
              onTap: () {
                context.pushNamed(ShareYourBalancePage.route);
              },
              icon: AppImages.balance,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),

            ProfileTile(
              label: 'Specials',
              onTap: () {
                context.pushNamed(
                  SpecialUrlPage.route,
                  extra: {'url': global?.specialUrl ?? ''},
                );
              },
              icon: AppImages.special,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),

            ProfileTile(
              label: 'Coffix QR ID',
              onTap: () {
                context.pushNamed(QrIdPage.route);
              },
              icon: AppImages.id,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),

            ProfileTile(
              label: 'Coffee on US',
              onTap: () {
                context.pushNamed(CoffeeOnUsPage.route);
              },
              icon: AppImages.coffee,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),

            ProfileTile(
              label: 'Coffee for Home',
              onTap: () {
                context.pushNamed(
                  CoffeeForHomePage.route,
                  extra: {'url': global?.storeUrl ?? ''},
                );
              },
              icon: AppImages.bag,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),

            const SizedBox(height: AppSizes.sm),
            ProfileTile(
              label: 'About',
              onTap: () {
                context.pushNamed(AboutPage.route);
              },
              icon: AppImages.info,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),

            ProfileTile(
              label: 'Logout',
              onTap: () {
                LogService().logout();
                context.read<AuthCubit>().signOut();
                context.read<CartCubit>().resetCart();
              },
              icon: AppImages.logout,
            ),
            Divider(height: 0, color: AppColors.textBlackColor),
            const SizedBox(height: AppSizes.xxxl),
          ],
        ),
      ),
    );
  }
}
