import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/personal_info_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppGuestBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String message,
    required bool isFinishedOnboarding,
    required bool isAuthenticated,
  }) {
    final needsOnboarding = isAuthenticated && !isFinishedOnboarding;

    return showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.md),
              AppButton.primary(
                label: needsOnboarding ? 'Go to Settings' : 'Sign In',
                onPressed: () {
                  context.pop();
                  if (needsOnboarding) {
                    context.goNamed(PersonalInfoPage.route, extra: {"canBack": true});
                  } else {
                    context.goNamed(HomePage.route);
                  }
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
