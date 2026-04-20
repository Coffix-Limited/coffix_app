import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/profile/logic/profile_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

class ShareYourBalancePage extends StatelessWidget {
  static String route = 'share_your_balance_route';
  const ShareYourBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<ProfileCubit>()),
      ],
      child: const ShareYourBalanceView(),
    );
  }
}

class ShareYourBalanceView extends StatefulWidget {
  const ShareYourBalanceView({super.key});

  @override
  State<ShareYourBalanceView> createState() => _ShareYourBalanceViewState();
}

class _ShareYourBalanceViewState extends State<ShareYourBalanceView> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<ProfileCubit>().state.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
    final global = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global, appVersion) => global,
      orElse: () => null,
    );
    return Scaffold(
      appBar: const AppBackHeader(title: 'My Coffix Credit Balance'),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          state.maybeWhen(
            success: () {
              AppNotification.show(context, 'Gift sent successfully');
              context.pop();
            },
            error: (message) {
              AppNotification.error(context, message);
            },
            orElse: () {},
          );
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final balance = state.maybeWhen(
              authenticated: (u) => u.user.creditAvailable ?? 0,
              orElse: () => 0.0,
            );

            return SafeArea(
              child: Padding(
                padding: AppSizes.defaultPadding,

                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: AppSizes.xxl),
                              AppCard(
                                color: AppColors.softGrey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: AppSizes.xs),
                                    Text.rich(
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyM.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      TextSpan(
                                        children: [
                                          TextSpan(text: 'You have '),
                                          balance.toCurrencySuperscript(
                                            style: AppTypography.headlineM
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          TextSpan(text: ' in Coffix Credit'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.xxl),
                              const SizedBox(height: AppSizes.md),

                              const SizedBox(height: AppSizes.md),
                              AppField<String>(
                                name: 'firstName',
                                label: 'Recipient first name',
                                hintText: 'First name',
                                isRequired: true,
                                validators: [
                                  (v) => (v ?? '').trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ],
                                isHorizontalAlign: true,
                              ),
                              const SizedBox(height: AppSizes.md),
                              AppField<String>(
                                name: 'lastName',
                                label: 'Recipient last name',
                                hintText: 'Last name',
                                isRequired: true,
                                validators: [
                                  (v) => (v ?? '').trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ],
                                isHorizontalAlign: true,
                              ),
                              const SizedBox(height: AppSizes.md),
                              AppField<String>(
                                name: 'email',
                                label: 'Recipient Email',
                                hintText: 'Email',
                                isRequired: true,
                                keyboardType: TextInputType.emailAddress,
                                validators: [FormBuilderValidators.email()],
                                isHorizontalAlign: true,
                                textCapitalization: TextCapitalization.none,
                              ),
                              const SizedBox(height: AppSizes.md),

                              AppField<String>(
                                name: 'amount',
                                label: 'Amount to gift',
                                hintText: '0.00',
                                isRequired: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                validators: [
                                  (v) {
                                    final n = double.tryParse(v ?? '');
                                    if (n == null || n <= 0 || n < 15) {
                                      return 'Enter a valid amount';
                                    }
                                    if (n > balance) {
                                      return 'Amount exceeds balance';
                                    }
                                    return null;
                                  },
                                ],
                                isHorizontalAlign: true,
                              ),
                              Row(
                                children: [
                                  SizedBox(width: 140.0),
                                  Text.rich(
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyXS.copyWith(),
                                    TextSpan(
                                      children: [
                                        TextSpan(text: 'Minimum of '),
                                        global?.minCreditToShare
                                                ?.toCurrencySuperscript(
                                                  style: AppTypography.bodyXS
                                                      .copyWith(),
                                                ) ??
                                            TextSpan(text: ''),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xxl),
                      Text(
                        "Please check the email address carefully as you can not undo this action!",
                        style: theme.textTheme.bodySmall?.copyWith(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      AppButton.primary(
                        disabled: isLoading,
                        onPressed: () {
                          if (_formKey.currentState?.saveAndValidate() ??
                              false) {
                            context.read<ProfileCubit>().sendGift(
                              recipientFirstName:
                                  _formKey.currentState!.value['firstName'] ??
                                  '',
                              recipientLastName:
                                  _formKey.currentState!.value['lastName'] ??
                                  '',
                              recipientEmail:
                                  _formKey.currentState!.value['email'] ?? '',
                              amount: double.parse(
                                _formKey.currentState!.value['amount'] ?? '0',
                              ),
                            );
                          }
                        },
                        label: isLoading ? 'Sending...' : 'Send a Gift',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
