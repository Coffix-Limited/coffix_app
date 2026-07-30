import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';

/// Shown when a reorder or draft cannot be loaded at all because none of its
/// products are still available at the selected store.
class ItemsUnavailableDialog extends StatelessWidget {
  const ItemsUnavailableDialog({super.key, required this.message});

  final String message;

  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog<void>(
      context: context,
      builder: (context) => ItemsUnavailableDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Items unavailable',
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
          child: AppButton.primary(
            onPressed: () => Navigator.of(context).pop(),
            label: 'OK',
          ),
        ),
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }
}
