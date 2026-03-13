import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

class PaymentSuccessfulPage extends StatelessWidget {
  static String route = 'payment_successful_route';
  const PaymentSuccessfulPage({super.key, required this.pickupAt});

  final DateTime pickupAt;

  @override
  Widget build(BuildContext context) {
    return PaymentSuccessfulView(pickupAt: pickupAt);
  }
}

class PaymentSuccessfulView extends StatelessWidget {
  const PaymentSuccessfulView({super.key, required this.pickupAt});

  final DateTime pickupAt;

  @override
  Widget build(BuildContext context) {
    final pickupTime = pickupAt;
    final timeText = DateFormat.jm().format(pickupTime);

    return Scaffold(
      appBar: AppBackHeader(title: "Order Confirmed", showBackButton: false),
      body: SafeArea(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle_rounded,
                size: AppSizes.iconSizeXLarge,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSizes.xxl),
              Text(
                'Payment successful',
                style: AppTypography.headlineXl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Your order will be ready for pickup at',
                style: AppTypography.bodyM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
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
                  timeText,
                  style: AppTypography.titleM.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              AppButton.primary(
                onPressed: () {
                  context.read<CartCubit>().resetCart();
                  context.goNamed(CartPage.route);
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
