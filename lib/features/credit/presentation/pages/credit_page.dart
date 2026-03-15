import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/credit/logic/credit_cubit.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_topup_page.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_topup_payment_page.dart';
import 'package:coffix_app/features/credit/presentation/widgets/info_card.dart';
import 'package:coffix_app/features/credit/presentation/widgets/tier_card.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

class CreditPage extends StatelessWidget {
  static String route = 'credit_route';
  const CreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<CreditCubit>(),
      child: const CreditView(),
    );
  }
}

class CreditView extends StatefulWidget {
  const CreditView({super.key});

  @override
  State<CreditView> createState() => _CreditViewState();
}

class _CreditViewState extends State<CreditView> {
  final formKey = GlobalKey<FormBuilderState>();

  double calculateTopUp(double amount) {
    double totalAmount = amount;

    if (amount < 50) {
      return totalAmount;
    } else if (amount < 250) {
      totalAmount += amount * 0.10;
    } else if (amount < 500) {
      totalAmount += amount * 0.15;
    } else {
      totalAmount += amount * 0.20;
    }

    return totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    final amount = formKey.currentState?.fields['amount']?.value;

    return Scaffold(
      appBar: AppBackHeader(title: "Coffix Credit", showBackButton: false),
      backgroundColor: AppColors.background,

      body: FormBuilder(
        key: formKey,
        onChanged: () {
          setState(() {
            formKey.currentState?.save();
          });
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSizes.defaultPadding,
            child: BlocConsumer<CreditCubit, CreditState>(
              listenWhen: (previous, current) => previous != current,
              listener: (context, state) {
                state.whenOrNull(
                  loaded: (paymentSessionUrl, _) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      context.pushNamed(
                        CreditTopupPaymentPage.route,
                        extra: {'paymentSessionUrl': paymentSessionUrl},
                      );
                    });
                  },
                );
              },
              builder: (context, state) {
                final showTopUpField = state.maybeWhen(
                  initial: (v) => v,
                  loading: (v) => v,
                  loaded: (_, v) => v,
                  error: (_, v) => v,
                  orElse: () => false,
                );
                if (state.maybeWhen(loading: (_) => true, orElse: () => false)) {
                  return const Center(child: AppLoading());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "PAY BY COFFIX CREDIT AND",
                        style: AppTypography.headlineL.copyWith(
                          color: AppColors.black,
                        ),
                        children: [
                          TextSpan(
                            text: " SAVE 10%- 20%",
                            style: AppTypography.headlineL.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoCard(
                            text: 'TopUp your Coffix Credit account',
                            image: AppImages.creditGray,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          InfoCard(
                            text: 'Order in your app',
                            image: AppImages.menuGray,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          InfoCard(
                            text: 'Get 10% - 20% discount for any order',
                            image: AppImages.creditGray,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    showTopUpField
                        ? Column(
                            children: [
                              Text("Please enter the amount you wish to TopUp"),
                              SizedBox(height: AppSizes.md),
                              AppField<String>(
                                label: "\$",
                                isHorizontalAlign: true,
                                hintText: "\$50+",
                                name: "amount",
                                keyboardType: TextInputType.number,
                                validators: [
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.min(0),
                                ],
                              ),
                              SizedBox(height: AppSizes.sm),
                              if (amount != null && amount.isNotEmpty)
                                Text(
                                  "You will receive: ${calculateTopUp(double.parse(amount ?? '0')).toStringAsFixed(2)}\$ Coffix Credits",
                                ),
                            ],
                          )
                        : Column(
                            children: [
                              TierCard(amount: 50, percent: '10%'),
                              const SizedBox(height: AppSizes.sm),
                              TierCard(amount: 250, percent: '15%'),
                              const SizedBox(height: AppSizes.sm),
                              TierCard(amount: 500, percent: '20%'),
                              const SizedBox(height: AppSizes.xl),
                            ],
                          ),
                    SizedBox(height: AppSizes.xl),
                    AppButton(
                      onPressed: () {
                        if (showTopUpField &&
                            formKey.currentState!.validate()) {
                          context.read<CreditCubit>().topup(
                            amount: double.parse(amount),
                          );
                        } else {
                          context.read<CreditCubit>().showTopUpField(true);
                        }
                      },
                      label: showTopUpField
                          ? "TopUp"
                          : "TopUp Your Coffix Credit",
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
