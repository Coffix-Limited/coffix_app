import 'dart:async';

import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/logic/otp_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_text_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';

class EmailVerificationForm extends StatefulWidget {
  const EmailVerificationForm({super.key});

  @override
  State<EmailVerificationForm> createState() => _EmailVerificationFormState();
}

class _EmailVerificationFormState extends State<EmailVerificationForm> {
  @override
  initState() {
    super.initState();
    context.read<OtpCubit>().sendEmailVerification();
  }

  final _pinController = TextEditingController();
  String _pin = '';

  static const _cooldownSeconds = 60;
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
      if (_secondsRemaining <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 48,
      textStyle: AppTypography.titleS.copyWith(),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(AppSizes.md),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(border: Border.all(color: AppColors.primary, width: 2)),
    );

    return BlocConsumer<OtpCubit, OtpState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        state.whenOrNull(
          error: (message) => AppNotification.error(context, message),
          otpSent: (message) => AppNotification.show(context, 'OTP sent to your email. Please check your email.'),
        );
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.xxxxl, top: AppSizes.xxl),
          child: Center(
            child: Container(
              padding: AppSizes.defaultPadding,
              decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(AppSizes.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Verify your email", style: AppTypography.titleS, textAlign: TextAlign.center),
                  const SizedBox(height: 12.0),
                  Text(
                    "Check your email and enter your verification code",
                    style: AppTypography.bodyXS,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  Pinput(
                    controller: _pinController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    onCompleted: (pin) => setState(() => _pin = pin),
                    onChanged: (pin) => setState(() => _pin = pin),
                  ),
                  const SizedBox(height: 24.0),
                  AppButton.primary(
                    disabled: _pin.length != 6 || state.maybeWhen(verifying: () => true, orElse: () => false),
                    onPressed: () {
                      context.read<OtpCubit>().verifyOtp(otp: _pin);
                    },
                    label: state.maybeWhen(verifying: () => 'Verifying...', orElse: () => "Next"),
                  ),
                  const SizedBox(height: 24.0),
                  Align(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.bodyXS,
                        children: [
                          TextSpan(
                            text: "Didn't receive the email? ",
                            style: AppTypography.bodyXS.copyWith(color: AppColors.black),
                          ),
                          if (state.maybeWhen(sending: () => true, orElse: () => false))
                            TextSpan(text: 'Sending...', style: AppTypography.bodyXS)
                          else if (_secondsRemaining > 0)
                            TextSpan(text: 'Try again in ${_secondsRemaining}s', style: AppTypography.bodyXS)
                          else
                            TextSpan(
                              text: 'Try again',
                              style: AppTypography.bodyXS.copyWith(decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  _pinController.clear();
                                  setState(() {
                                    _pin = '';
                                  });
                                  LogService().getOTP();
                                  await context.read<OtpCubit>().sendEmailVerification();
                                  if (!context.mounted) return;
                                  _startCooldown();
                                  AppNotification.show(context, 'OTP sent to your email. Please check your email.');
                                },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Center(
                    child: AppTextButton(
                      text: "Logout",
                      showUnderline: true,
                      onPressed: () {
                        context.read<AuthCubit>().signOut();
                      },
                      textStyle: AppTypography.bodyS.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: AppColors.textBlackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
