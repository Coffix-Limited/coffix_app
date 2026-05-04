import 'dart:io';

import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_icon_button.dart';
import 'package:coffix_app/presentation/atoms/app_text_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.formKey});
  final GlobalKey<FormBuilderState> formKey;
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  void handleLogin() async {
    if (widget.formKey.currentState?.saveAndValidate() ?? false) {
      final fields = widget.formKey.currentState!.value;
      widget.formKey.currentState?.reset();
      await context.read<AuthCubit>().createOrLoginAccount(
        email: fields['email'] as String,
        password: fields['password'] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (_) => widget.formKey.currentState?.reset(),
        );
      },
      child: Column(
        children: [
          const SizedBox(height: AppSizes.xxxxl),
          Center(
            child: Container(
              padding: AppSizes.defaultPadding,
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Create Your Coffix Account",
                    textAlign: TextAlign.center,
                    style: AppTypography.titleS,
                  ),
                  const SizedBox(height: 25.0),
                  Text(
                    "First, enter your email address and password",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10.0),
                  AppField(
                    hintText: "Email",
                    name: "email",
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 14.0),
                  AppField(
                    hintText: "Password",
                    name: "password",
                    obscureText: true,
                    isRequired: true,
                    validators: [
                      (String? value) {
                        if (value == null || value.isEmpty) return null;
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (value.length > 4096) {
                          return 'Password must not exceed 4096 characters';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Password must contain an uppercase letter';
                        }
                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return 'Password must contain a lowercase letter';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Password must contain a number';
                        }
                        if (!RegExp(
                          r'[!@#$%^&*(),.?":{}|<>_\-\+=\[\]\\\/~`]',
                        ).hasMatch(value)) {
                          return 'Password must contain a special character';
                        }
                        return null;
                      },
                    ],
                  ),
                  const SizedBox(height: 14.0),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: AppButton(onPressed: handleLogin, label: "Next"),
                  ),
                  const SizedBox(height: 14.0),
                  Center(
                    child: AppTextButton(
                      text: "Forgot my password",
                      onPressed: () {
                        context.read<AuthCubit>().forgotPassword();
                      },
                      showUnderline: true,
                      textStyle: AppTypography.bodyXS.copyWith(
                        decoration: TextDecoration.underline,
                        color: AppColors.textBlackColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text("or sign up with", textAlign: TextAlign.left),
                  const SizedBox(height: 14.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AppIconButton.withSvgPath(
                        AppImages.google,
                        onPressed: () {
                          context.read<AuthCubit>().signInWithGoogle();
                        },
                        backgroundColor: Colors.white,
                      ),

                      // TODO: FIX THIS ONCE FACEBOOK IS ALREADY IMPLEMENTED
                      // AppIconButton.withSvgPath(
                      //   AppImages.facebook,
                      //   onPressed: () {},
                      //   backgroundColor: Colors.white,
                      // ),
                      if (Platform.isIOS)
                        AppIconButton.withSvgPath(
                          AppImages.apple,
                          onPressed: () {
                            context.read<AuthCubit>().signInWithApple();
                          },
                          backgroundColor: Colors.white,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xxxxl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.bodyXS,
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
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await launchUrl(
                                  Uri.parse(
                                    'https://www.coffix.co.nz/term-of-use-privacy',
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xxxxl),
        ],
      ),
    );
  }
}
