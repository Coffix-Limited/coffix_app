import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';

class AppError extends StatelessWidget {
  const AppError({super.key, required this.title, required this.subtitle, this.onRetry, this.actionButton});

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final Widget? actionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: AppSizes.iconSizeXLarge, color: AppColors.error),
            const SizedBox(height: AppSizes.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.black),
            ),
            const SizedBox(height: AppSizes.xxl),
            if (onRetry != null) ...[
              AppButton.primary(onPressed: onRetry!, label: 'Retry'),
              const SizedBox(height: AppSizes.xxl),
            ],
            if (actionButton != null) ...[actionButton!, const SizedBox(height: AppSizes.xxl)],
          ],
        ),
      ),
    );
  }
}
