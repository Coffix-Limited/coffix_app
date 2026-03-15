import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/features/order/presentation/pages/order_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PaymentSuccessfulPage extends StatelessWidget {
  static String route = 'payment_successful_route';
  const PaymentSuccessfulPage({
    super.key,
    required this.pickupAt,
    this.orderNumber,
  });

  final DateTime pickupAt;
  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    return PaymentSuccessfulView(pickupAt: pickupAt, orderNumber: orderNumber);
  }
}

class PaymentSuccessfulView extends StatelessWidget {
  const PaymentSuccessfulView({
    super.key,
    required this.pickupAt,
    this.orderNumber,
  });

  final DateTime pickupAt;
  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat.jm().format(pickupAt);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Center(
            child: Container(
              padding: AppSizes.defaultPadding,
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'THANK YOU!',
                    style: AppTypography.headlineXl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    orderNumber != null
                        ? 'Order #$orderNumber will be ready for pick up at'
                        : 'Your order will be ready for pick up at',
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
                  const SizedBox(height: AppSizes.xl),
                  AppButton.primary(
                    onPressed: () {
                      context.read<CartCubit>().resetCart();
                      context.goNamed(HomePage.route);
                    },
                    label: 'OK',
                  ),
                  const SizedBox(height: AppSizes.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
