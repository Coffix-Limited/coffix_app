import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/coupons/data/model/coupon.dart';
import 'package:coffix_app/features/coupons/logic/coupon_cubit.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_page.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:coffix_app/features/payment/logic/payment_cubit.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_page.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_successful_page.dart';
import 'package:coffix_app/features/payment/presentation/widgets/payment_option.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PaymentOptionsPage extends StatelessWidget {
  static String route = 'payment_options_route';
  const PaymentOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<PaymentCubit>()),
        BlocProvider.value(value: getIt<CouponCubit>()),
      ],
      child: const PaymentOptionsPageView(),
    );
  }
}

class PaymentOptionsPageView extends StatefulWidget {
  const PaymentOptionsPageView({super.key});

  @override
  State<PaymentOptionsPageView> createState() => _PaymentOptionsPageViewState();
}

class _PaymentOptionsPageViewState extends State<PaymentOptionsPageView> {
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
    final theme = Theme.of(context);
    final total =
        context.watch<CartCubit>().state.cart?.items?.fold(
          0.0,
          (sum, item) => sum + item.lineTotal,
        ) ??
        0.0;
    final cart = context.watch<CartCubit>().state.cart;
    final paymentMethod = context.watch<CartCubit>().state.cart?.paymentMethod;
    final creditAvailable = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (u) => u.user.creditAvailable ?? 0,
      orElse: () => 0.0,
    );
    final coupons = context.watch<CouponCubit>().state.maybeWhen(
      loaded: (coupons) => coupons,
      orElse: () => <Coupon>[],
    );
    final totalCoupon = coupons.fold(0.0, (sum, c) => sum + (c.amount ?? 0.0));
    final totalBalance = creditAvailable + totalCoupon;
    final insufficientCredit =
        paymentMethod == PaymentMethod.coffixCredit && totalBalance < total;

    return Scaffold(
      appBar: AppBackHeader(title: "Payment"),
      body: Column(
        children: [
          BlocConsumer<PaymentCubit, PaymentState>(
            listener: (context, state) {
              state.whenOrNull(
                success: (order) {
                  context.goNamed(
                    PaymentSuccessfulPage.route,
                    extra: {
                      "pickupAt": order.scheduledAt,
                      "orderNumber": order.transactionNumber,
                    },
                  );
                  context.read<CartCubit>().resetCart();
                },
                error: (message) {
                  AppNotification.error(context, message);
                },
              );
            },
            builder: (context, state) {
              if (state == PaymentState.loading()) {
                return Expanded(
                  child: Center(
                    child: Text(
                      "Processing your payment...",
                      style: AppTypography.bodyXS.copyWith(),
                    ),
                  ),
                );
              }
              return Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: AppSizes.defaultPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.lg,
                                vertical: AppSizes.md,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'You are paying',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Text.rich(
                                    total.toCurrencySuperscript(
                                      style: AppTypography.labelL,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.xxl),
                            Text(
                              'Select payment method',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSizes.lg),
                            PaymentOption(
                              selected:
                                  paymentMethod == PaymentMethod.coffixCredit,
                              onTap: () {
                                context.read<CartCubit>().setPaymentMethod(
                                  PaymentMethod.coffixCredit,
                                );
                              },
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Coffix Credit',
                              subtitle: 'Save 10–20% on your order',
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text.rich(
                                    totalBalance.toCurrencySuperscript(
                                      style: AppTypography.labelM,
                                    ),
                                  ),
                                  AppButton(
                                    textStyle: AppTypography.labelS.copyWith(
                                      color: AppColors.white,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.md,
                                      vertical: AppSizes.xs,
                                    ),
                                    label: "TopUp",
                                    onPressed: () {
                                      context.pushNamed(CreditPage.route);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (insufficientCredit)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSizes.sm,
                                  left: AppSizes.md,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Insufficient balance. ',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppSizes.sm),
                            PaymentOption(
                              selected: paymentMethod == PaymentMethod.card,
                              onTap: () {
                                context.read<CartCubit>().setPaymentMethod(
                                  PaymentMethod.card,
                                );
                              },
                              icon: Icons.credit_card,
                              title: 'Debit/Credit Card',
                              subtitle:
                                  'Pay with card, Apple Pay, or Google Pay',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: AppSizes.defaultPadding,
                        child: AppButton.primary(
                          disabled:
                              cart == null ||
                              paymentMethod == null ||
                              insufficientCredit,
                          onPressed: () {
                            if (cart == null) return;
                            final request = PaymentRequest(
                              storeId: cart.storeId ?? "",
                              items:
                                  cart.items
                                      ?.map(
                                        (item) => PaymentItem(
                                          productId: item.productId ?? '',
                                          quantity: item.quantity ?? 0,
                                          selectedModifiers:
                                              item.selectedByGroup,
                                        ),
                                      )
                                      .toList() ??
                                  [],
                              duration: cart.duration ?? 0,
                              paymentMethod:
                                  cart.paymentMethod ??
                                  PaymentMethod.coffixCredit,
                            );
                            if (paymentMethod == PaymentMethod.coffixCredit) {
                              context.read<PaymentCubit>().createPayment(
                                request: request,
                              );
                            } else {
                              context.pushNamed(
                                PaymentPage.route,
                                extra: {"paymentRequest": request},
                              );
                            }
                          },
                          label: paymentMethod == PaymentMethod.coffixCredit
                              ? 'Pay with Coffix Credit'
                              : 'Pay with Card',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
