import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/auth/data/model/user_with_store.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_options_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum PickupOption { now, fifteenMinutes, thirtyMinutes }

double _durationMinutes(PickupOption option) {
  switch (option) {
    case PickupOption.now:
      return 0;
    case PickupOption.fifteenMinutes:
      return 15;
    case PickupOption.thirtyMinutes:
      return 30;
  }
}

class ScheduleOrderPage extends StatelessWidget {
  static String route = 'schedule_order_route';
  const ScheduleOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScheduleOrderView();
  }
}

class ScheduleOrderView extends StatefulWidget {
  const ScheduleOrderView({super.key});

  @override
  State<ScheduleOrderView> createState() => _ScheduleOrderViewState();
}

class _ScheduleOrderViewState extends State<ScheduleOrderView> {
  PickupOption _selected = PickupOption.now;

  String _label(PickupOption option) {
    switch (option) {
      case PickupOption.now:
        return 'Now';
      case PickupOption.fifteenMinutes:
        return 'In 15 minutes';
      case PickupOption.thirtyMinutes:
        return 'In 30 minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppUserWithStore? user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    return Scaffold(
      appBar: AppBackHeader(title: "Pickup time"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSizes.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'At what time do you want to collect your order from ${user?.store?.name}?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  for (final option in PickupOption.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: AppClickable(
                        onPressed: () => setState(() => _selected = option),
                        borderRadius: BorderRadius.circular(AppSizes.md),
                        child: AppCard(
                          borderColor: _selected == option
                              ? AppColors.primary
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: AppSizes.md,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selected == option
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: _selected == option
                                    ? AppColors.primary
                                    : AppColors.lightGrey,
                                size: AppSizes.iconSizeMedium,
                              ),
                              const SizedBox(width: AppSizes.md),
                              Text(
                                _label(option),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppSizes.defaultPadding,
              child: AppButton.primary(
                onPressed: () {
                  getIt<CartCubit>().pickTime(_durationMinutes(_selected));
                  context.pushNamed(PaymentOptionsPage.route);
                },
                label: 'Pay',
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}
