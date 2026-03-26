import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/presentation/pages/login_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/organisms/app_layout_body.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

class CreateAccountPage extends StatelessWidget {
  static String route = 'create_account_route';
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: const CreateAccountView(),
    );
  }
}

class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _onNext() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final fields = _formKey.currentState!.value;
      context.read<AuthCubit>().createAccountWithEmailAndPassword(
        email: fields['email'] as String,
        password: fields['password'] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: AppLayoutBody(
        child: FormBuilder(
          key: _formKey,
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              // state.whenOrNull(
              //   authenticated: (user) => context.go('/'),
              //   error: (message) => AppSnackbar.showError(context, message),
              // );
            },
            builder: (context, state) {
              if (state == AuthState.loading()) {
                return const Center(child: AppLoading());
              }
              return Padding(
                padding: AppSizes.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.xxl),
                    AppField<String>(
                      name: 'email',
                      label: 'Email',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      isRequired: true,
                      validators: [FormBuilderValidators.email()],
                    ),
                    const SizedBox(height: AppSizes.lg),
                    AppField<String>(
                      name: 'password',
                      label: 'Password',
                      hintText: 'Create a password',
                      obscureText: true,
                      showPasswordToggle: true,
                      isRequired: true,
                    ),

                    const SizedBox(height: AppSizes.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(),
                          children: [
                            TextSpan(
                              text: "Already have an account? ",
                              style: AppTypography.bodyXS.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                            TextSpan(
                              text: 'Login',
                              style: AppTypography.bodyXS.copyWith(
                                color: AppColors.accent,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.accent,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  context.goNamed(LoginPage.route);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    Spacer(),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(),
                        children: [
                          TextSpan(
                            text: "By registering you accept our ",
                            style: AppTypography.bodyXS.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'Terms of Use & Privacy',
                            style: AppTypography.bodyXS.copyWith(
                              decoration: TextDecoration.underline,
                              color: AppColors.accent,
                              decorationColor: AppColors.accent,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppButton.primary(onPressed: _onNext, label: 'Next'),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
