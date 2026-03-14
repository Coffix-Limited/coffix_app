import 'package:another_flushbar/flushbar.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_snackbar.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpecialUrlPage extends StatelessWidget {
  static String route = 'special_url_route';
  const SpecialUrlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AppCubit>(),
      child: const SpecialUrlView(),
    );
  }
}

class SpecialUrlView extends StatelessWidget {
  const SpecialUrlView({super.key});

  @override
  Widget build(BuildContext context) {
    final global = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global) => global,
      orElse: () => null,
    );
    return Scaffold(
      appBar: const AppBackHeader(title: 'Special Url'),
      body: Padding(
        padding: AppSizes.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSizes.xxl),
            Column(
              children: [
                Text(global?.specialUrl ?? '', style: AppTypography.bodyL),
                const SizedBox(height: AppSizes.lg),
                AppButton.primary(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: global?.specialUrl ?? ''),
                    );
                    AppNotification.show(
                      context,
                      'Copied to clipboard',
                      position: FlushbarPosition.BOTTOM,
                    );
                  },
                  label: 'Copy',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
