import 'dart:async';

import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/features/auth/logic/otp_cubit.dart';
import 'package:coffix_app/features/profile/presentation/pages/personal_info_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

class VerifyEmailPage extends StatelessWidget {
  static String route = 'verify_email_route';
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<OtpCubit>(),
      child: VerifyEmailView(email: email),
    );
  }
}

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final _pinController = TextEditingController();
  String _pin = '';
  static const _resendCooldownSeconds = 180;
  int _remainingSeconds = _resendCooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<OtpCubit>().sendEmailVerification();
    LogService().getOTP();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remainingSeconds = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds <= 1) {
          _remainingSeconds = 0;
          _timer?.cancel();
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  String get _timerText {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _onVerify() {
    if (_pin.length != 6) return;
    LogService().verifyOTP();
    context.read<OtpCubit>().verifyOtp(otp: _pin);
  }

  void _onResendOtp() {
    LogService().getOTP();
    context.read<OtpCubit>().sendEmailVerification();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(AppSizes.md),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: BlocConsumer<OtpCubit, OtpState>(
          listener: (context, state) {
            state.whenOrNull(
              otpSent: (email) => AppNotification.show(
                context,
                'OTP sent to $email. Please check your email.',
              ),
              error: (message) {
                LogService().otpError();
                AppNotification.error(context, message);
              },
              verified: () => context.goNamed(
                PersonalInfoPage.route,
                extra: {"canBack": false},
              ),
            );
          },
          builder: (context, state) {
            if (state.maybeWhen(verifying: () => true, orElse: () => false)) {
              return const Center(child: AppLoading());
            }
            final canResend = _remainingSeconds == 0;
            return SingleChildScrollView(
              padding: AppSizes.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.xxl),
                  Text(
                    'Verify your email',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Enter your verification code',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  Pinput(
                    controller: _pinController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    onCompleted: (pin) => setState(() => _pin = pin),
                    onChanged: (pin) => setState(() => _pin = pin),
                  ),
                  const SizedBox(height: AppSizes.xxxl),
                  AppButton.primary(
                    onPressed: _onVerify,
                    disabled: _pin.length != 6,
                    label: 'Verify',
                  ),
                  const SizedBox(height: AppSizes.md),
                  Center(
                    child: canResend
                        ? AppTextButton(
                            onPressed: _onResendOtp,
                            text: 'Resend OTP',
                          )
                        : Text(
                            'Resend code in $_timerText',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.lightGrey,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
