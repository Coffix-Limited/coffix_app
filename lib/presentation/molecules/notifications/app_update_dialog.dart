import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.onUpdate,
    this.isDismissable = true,
    required this.title,
    required this.message,
  });

  final bool isDismissable;
  final String title;
  final String message;
  final VoidCallback onUpdate;

  static Future<bool?> show(
    BuildContext context, {
    required VoidCallback onUpdate,
    bool isDismissable = true,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: isDismissable,
      builder: (context) => AppUpdateDialog(
        onUpdate: () {
          Navigator.of(context).pop(true);
          onUpdate();
        },
        isDismissable: isDismissable,
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        title,
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: AppButton.primary(onPressed: onUpdate, label: 'Update Now'),
        ),
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }
}
