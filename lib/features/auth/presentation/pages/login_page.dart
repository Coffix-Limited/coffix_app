import 'dart:io';

import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/presentation/pages/create_account_page.dart';
import 'package:coffix_app/features/wrapper/presentation/pages/wrapper_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_icon_button.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_text_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  static String route = 'login_route';
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _onLogin() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      context.read<AuthCubit>().signInWithEmailAndPassword(
        email: _formKey.currentState!.value['email'] as String,
        password: _formKey.currentState!.value['password'] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.defaultPadding,
          child: FormBuilder(
            key: _formKey,
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                state.whenOrNull(
                  authenticated: (_) => context.goNamed(WrapperPage.route),
                  error: (message) => AppNotification.error(context, message),
                );
              },
              builder: (context, state) {
                if (state == AuthState.loading()) {
                  return const Center(child: AppLoading());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvgPicture.asset(
                      AppImages.nameLogo,
                      height: 100,
                      width: 100,
                    ),
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
                      hintText: 'Enter your password',
                      obscureText: true,
                      showPasswordToggle: true,
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppTextButton(
                        text: 'Forgot password?',
                        onPressed: () {},
                        textStyle: AppTypography.bodyXS.copyWith(
                          color: AppColors.accent,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxxxl),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.borderColor,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                          ),
                          child: Text(
                            "or continue with",
                            style: AppTypography.body2XS,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.borderColor,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AppIconButton.withSvgPath(
                          AppImages.google,
                          onPressed: () {
                            context.read<AuthCubit>().signInWithGoogle();
                          },
                        ),
                        const SizedBox(width: AppSizes.lg),

                        // TODO: FIX THIS ONCE FACEBOOK IS ALREADY IMPLEMENTED
                        // AppIconButton.withSvgPath(
                        //   AppImages.facebook,
                        //   onPressed: () {},
                        // ),
                        if (Platform.isIOS)
                          AppIconButton.withSvgPath(
                            AppImages.apple,
                            onPressed: () {
                              context.read<AuthCubit>().signInWithApple();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xxxxl),
                    Align(
                      alignment: Alignment.centerRight,
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.bodyXS,
                          children: [
                            TextSpan(
                              text: "Don't have an account? ",
                              style: AppTypography.bodyXS.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                            TextSpan(
                              text: 'Create an account',
                              style: AppTypography.bodyXS.copyWith(
                                color: AppColors.accent,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.accent,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  context.goNamed(CreateAccountPage.route);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    AppButton.primary(onPressed: _onLogin, label: 'Log in'),
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
