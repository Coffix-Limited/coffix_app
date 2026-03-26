import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/credit/logic/credit_cubit.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_topup_payment_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreditTopupPage extends StatelessWidget {
  static String route = 'credit_topup_route';

  const CreditTopupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreditCubit>(),
      child: const CreditTopupView(),
    );
  }
}

class CreditTopupView extends StatefulWidget {
  const CreditTopupView({super.key});

  @override
  State<CreditTopupView> createState() => _CreditTopupViewState();
}

class _CreditTopupViewState extends State<CreditTopupView> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocConsumer<CreditCubit, CreditState>(
        listener: (context, state) {
          state.whenOrNull(
            loaded: (url, _) {
              context.pushNamed(
                CreditTopupPaymentPage.route,
                extra: {'paymentSessionUrl': url},
              );
            },
            error: (message, _) {
              AppNotification.error(context, 'TopUp failed: $message');
            },
          );
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: AppSizes.defaultPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppBackHeader(title: "TopUp Coffix Credit"),
                    const SizedBox(height: AppSizes.xxl),
                    Text('Enter amount', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.md),
                        ),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    if (state == CreditState.loading())
                      AppLoading()
                    else
                      AppButton.primary(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final amount =
                                double.tryParse(_amountController.text) ?? 0;
                            context.read<CreditCubit>().topup(amount: amount);
                          }
                        },
                        label: 'Continue to payment',
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
