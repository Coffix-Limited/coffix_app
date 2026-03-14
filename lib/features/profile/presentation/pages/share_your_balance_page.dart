import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ShareYourBalancePage extends StatelessWidget {
  static String route = 'share_your_balance_route';
  const ShareYourBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
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
    return Scaffold(
      appBar: const AppBackHeader(title: 'Share your balance'),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final balance = state.maybeWhen(
            authenticated: (u) => u.user.creditAvailable ?? 0,
            orElse: () => 0.0,
          );

          return SafeArea(
            child: SingleChildScrollView(
              padding: AppSizes.defaultPadding,
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.xxl),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Your balance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.lightGrey,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            '\$${balance.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    Text(
                      'Recipient details',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppField<String>(
                      name: 'email',
                      label: 'Email',
                      hintText: 'Email',
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                      validators: [FormBuilderValidators.email()],
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppField<String>(
                      name: 'firstName',
                      label: 'First name',
                      hintText: 'First name',
                      isRequired: true,
                      validators: [
                        (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppField<String>(
                      name: 'lastName',
                      label: 'Last name',
                      hintText: 'Last name',
                      isRequired: true,
                      validators: [
                        (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppField<String>(
                      name: 'amount',
                      label: 'Amount',
                      hintText: '0.00',
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(
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
                          if (n == null || n <= 0)
                            return 'Enter a valid amount';
                          if (n > balance) return 'Amount exceeds balance';
                          return null;
                        },
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      "Minimum of \$15",
                      style: theme.textTheme.bodyMedium?.copyWith(),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    Text(
                      "Please check the email address carefully as you can not undo this action!",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.lightGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    AppButton.primary(
                      onPressed: () {
                        if (_formKey.currentState?.saveAndValidate() ?? false) {
                          // TODO: call share/gift API with _formKey.currentState!.value
                        }
                      },
                      label: 'Gift',
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
