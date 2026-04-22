import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';

class AppGuestBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String message,
    required VoidCallback onSignIn,
    required VoidCallback onCreateAccount,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.md),
              AppButton.primary(
                label: 'Sign In',
                onPressed: () {
                  Navigator.pop(context);
                  onSignIn();
                },
              ),
              const SizedBox(height: AppSizes.md),
              AppButton.outlined(
                label: 'Create Account',
                onPressed: () {
                  Navigator.pop(context);
                  onCreateAccount();
                },
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
