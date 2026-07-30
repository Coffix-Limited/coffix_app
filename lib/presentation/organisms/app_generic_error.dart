import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppGenericError extends StatelessWidget {
  const AppGenericError({super.key, this.title, this.subtitle, this.error, this.onRetry});

  final String? title;
  final String? subtitle;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppError(
                title: title ?? 'Something went wrong',
                subtitle: subtitle ?? 'We could not open this page. Please try again.',
                onRetry: onRetry,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: AppButton.outlined(onPressed: () => context.goNamed(HomePage.route), label: 'Go home'),
              ),
              if (kDebugMode && error != null) ...[
                const SizedBox(height: AppSizes.xxl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.lightGrey, fontFamily: 'monospace'),
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
