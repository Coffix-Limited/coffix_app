import 'package:another_flushbar/flushbar.dart';
import 'package:coffix_app/core/constants/colors.dart';
import 'package:flutter/material.dart';

class AppNotification extends StatelessWidget {
  const AppNotification({super.key, required this.message});

  final String message;

  static void show(
    BuildContext context,
    String message, {
    FlushbarPosition? position,
  }) {
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        message: message,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: position ?? FlushbarPosition.TOP,
        backgroundColor: AppColors.success,
      ).show(rootContext);
    });
  }

  static void error(
    BuildContext context,
    String message, {
    FlushbarPosition? position,
  }) {
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        message: message,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: position ?? FlushbarPosition.TOP,
        backgroundColor: AppColors.error,
      ).show(rootContext);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Flushbar(
      message: message,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
    );
  }
}
