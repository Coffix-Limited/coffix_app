import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppGuestBottomSheet {
  static Future<void> show(BuildContext context, {required String message}) {
    return showModalBottomSheet(
      useRootNavigator: true,
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
                  context.pop();
                  context.goNamed(HomePage.route);
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
