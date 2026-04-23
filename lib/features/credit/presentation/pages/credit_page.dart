import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/data/model/global.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/presentation/pages/login_page.dart';
import 'package:coffix_app/features/credit/logic/credit_cubit.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_topup_payment_page.dart';
import 'package:coffix_app/features/credit/presentation/widgets/info_card.dart';
import 'package:coffix_app/features/credit/presentation/widgets/tier_card.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_layout_builder.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_money_field.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/app_guest_bottom_sheet.dart';
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
  bool _amountInitialized = false;

  double calculateTopUp(double amount, AppGlobal global) {
    double totalAmount = amount;

    if (amount < (global.minTopUp ?? 0)) {
      return totalAmount;
    } else if (amount < (global.topupLevel2 ?? 0)) {
      totalAmount += amount * ((global.basicDiscount ?? 0) / 100);
    } else if (amount < (global.topupLevel3 ?? 0)) {
      totalAmount += amount * ((global.discountLevel2 ?? 0) / 100);
    } else {
      totalAmount += amount * ((global.discountLevel3 ?? 0) / 100);
    }

    return totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    final global = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global, appVersion) => global,
      orElse: () => null,
    );
    final minTopUp = global?.minTopUp?.toStringAsFixed(0);
    if (!_amountInitialized && minTopUp != null) {
      _amountInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        formKey.currentState?.fields['amount']?.didChange(minTopUp);
      });
    }
    final amount =
        formKey.currentState?.fields['amount']?.value ?? minTopUp ?? '0';
    final parsedAmount = double.tryParse(amount) ?? 0;

    final bool minTopUpNotReached =
        parsedAmount < double.parse(minTopUp ?? '0');
    final isAuthenticated = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) =>
          user.user.emailVerified == true &&
          user.user.finishedOnboarding == true,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBackHeader(
        title: "Coffix Credit",
        onBack: () {
          context.goNamed(HomePage.route);
        },
        showLocation: false,
      ),
      backgroundColor: AppColors.background,

      body: FormBuilder(
        key: formKey,
        initialValue: {"amount": minTopUp},
        onChanged: () {
          setState(() {
            formKey.currentState?.save();
          });
        },
        child: SafeArea(
          child: AppLayoutBuilder(
            child: BlocConsumer<CreditCubit, CreditState>(
              listenWhen: (previous, current) => previous != current,
              listener: (context, state) {
                state.whenOrNull(
                  loaded: (paymentSessionUrl, amount, transactionNumber, _) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      context.pushNamed(
                        CreditTopupPaymentPage.route,
                        extra: {
                          'paymentSessionUrl': paymentSessionUrl,
                          'amount': amount,
                          'transactionNumber': transactionNumber,
                        },
                      );
                      context.read<CreditCubit>().reset();
                    });
                  },
                );
              },
              builder: (context, state) {
                final showTopUpField = state.maybeWhen(
                  initial: (v) => v,
                  loading: (v) => v,
                  loaded: (url, amount, txNum, v) => v,
                  error: (_, v) => v,
                  orElse: () => false,
                );
                if (state.maybeWhen(
                  loading: (_) => true,
                  orElse: () => false,
                )) {
                  return const Center(child: AppLoading());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: "PAY BY COFFIX CREDIT AND",
                          style: AppTypography.headlineL.copyWith(
                            color: AppColors.black,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  " \nSAVE ${global?.basicDiscount?.toInt()}%- ${global?.discountLevel3?.toInt()}%",
                              style: AppTypography.headlineL.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    if (!showTopUpField)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoCard(
                              text: 'TopUp your Coffix Credit account',
                              image: AppImages.card,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            InfoCard(
                              text: 'Order in your App',
                              image: AppImages.menuGray,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            InfoCard(
                              text:
                                  'Get ${global?.basicDiscount?.toInt()}% - ${global?.discountLevel3?.toInt()}% discount for any order',
                              image: AppImages.creditGray,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSizes.xl),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.md,
                      ),
                      decoration: BoxDecoration(border: Border.all()),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSizes.lg),
                          TierCard(
                            amount: double.parse(
                              global?.minTopUp?.toString() ?? '0',
                            ),
                            percent: '${global?.basicDiscount?.toInt()}%',
                          ),
                          const SizedBox(height: AppSizes.sm),
                          TierCard(
                            amount: double.parse(
                              global?.topupLevel2?.toString() ?? '0',
                            ),
                            percent: '${global?.discountLevel2?.toInt()}%',
                          ),
                          const SizedBox(height: AppSizes.sm),
                          TierCard(
                            amount: double.parse(
                              global?.topupLevel3?.toString() ?? '0',
                            ),
                            percent: '${global?.discountLevel3?.toInt()}%',
                          ),
                        ],
                      ),
                    ),
                    if (showTopUpField)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.xxxxxl),
                        child: Column(
                          children: [
                            Text(
                              "Please enter the amount you wish to TopUp. Minimum top up is \$${global?.minTopUp?.toStringAsFixed(0)}",
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppSizes.md),
                            AppMoneyField(
                              name: 'amount',
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.min(
                                  global?.minTopUp ?? 0,
                                ),
                              ],
                              maxLength: 5,
                            ),

                            // AppField<String>(
                            //   label: "\$",
                            //   isHorizontalAlign: true,
                            //   hintText: "\$50+",
                            //   name: "amount",
                            //   keyboardType: TextInputType.number,
                            //   validators: [
                            //     FormBuilderValidators.required(),
                            //     FormBuilderValidators.min(0),
                            //   ],
                            // ),
                            SizedBox(height: AppSizes.sm),
                            !minTopUpNotReached
                                ? Text(
                                    "You will receive: \$${calculateTopUp(parsedAmount, global ?? AppGlobal()).toStringAsFixed(2)} Coffix Credits",
                                  )
                                : Text("Minimum top up is \$$minTopUp"),
                          ],
                        ),
                      ),

                    SizedBox(height: AppSizes.xl),
                    Spacer(),
                    AppButton(
                      disabled:
                          (showTopUpField &&
                          (amount.isEmpty ||
                              parsedAmount < (global?.minTopUp ?? 0))),
                      onPressed: () {
                        if (!isAuthenticated) {
                          AppGuestBottomSheet.show(
                            context,
                            message: "Please sign in to continue",
                          );
                        } else if (showTopUpField &&
                            formKey.currentState!.validate()) {
                          context.read<CreditCubit>().topup(
                            amount: parsedAmount,
                          );
                        } else {
                          context.read<CreditCubit>().showTopUpField(true);
                        }
                      },
                      label: showTopUpField
                          ? "TopUp"
                          : "TopUp Your Coffix Credit",
                    ),
                    SizedBox(height: AppSizes.xl),
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
