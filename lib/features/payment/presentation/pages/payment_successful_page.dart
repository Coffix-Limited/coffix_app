import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/payment/logic/payment_cubit.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<PaymentCubit>()),
        BlocProvider.value(value: getIt<StoreCubit>()),
      ],
      child: PaymentSuccessfulView(pickupAt: pickupAt),
    );
  }
}

class PaymentSuccessfulView extends StatelessWidget {
  const PaymentSuccessfulView({super.key, required this.pickupAt});

  final DateTime pickupAt;

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat.jm().format(pickupAt);
    final Order? orderCreated = context.read<PaymentCubit>().state.maybeWhen(
      loaded: (_, order) => order,
      success: (order) => order,
      orElse: () => null,
    );
    final Store? store = orderCreated?.storeId != null
        ? context.watch<StoreCubit>().state.maybeWhen(
            loaded: (stores) =>
                stores.firstWhere((s) => s.docId == orderCreated?.storeId),
            orElse: () => null,
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.black.withValues(alpha: 0.7),
      body: SafeArea(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(AppImages.nameLogo, width: 124.0, height: 64.0),
              Center(
                child: Container(
                  padding: AppSizes.defaultPadding,
                  decoration: BoxDecoration(
                    color: AppColors.beige,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: BlocBuilder<PaymentCubit, PaymentState>(
                    builder: (context, state) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'THANK YOU!',
                            style: AppTypography.headlineXl,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            orderCreated != null
                                ? 'Order #${orderCreated.orderNumber?.substring(orderCreated.orderNumber!.length - 6) ?? '—'} will be ready for pick up from \n${store?.name ?? '—'} at'
                                : 'Your order will be ready for pick up from \n${store?.name ?? '—'} at',
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
                      );
                    },
                  ),
                ),
              ),
              Opacity(
                opacity: 0.6,
                child: Column(
                  children: [
                    AppButton.primary(
                      color: AppColors.lightGrey,
                      onPressed: () {},
                      label: "New Order",
                      disabled: true,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.primary(
                            disabled: true,
                            onPressed: () async {},
                            label: "ReOrder",
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: AppButton.primary(
                            disabled: true,
                            onPressed: () {},
                            label: "My Drafts",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
