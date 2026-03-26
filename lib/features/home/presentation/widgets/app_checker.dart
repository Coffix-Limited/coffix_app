import 'package:coffix_app/core/constants/constants.dart';
import 'package:coffix_app/features/app/data/model/global.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/presentation/molecules/notifications/app_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppCheckerState { updateRequired, updateWarning, upToDate }

class AppChecker extends StatefulWidget {
  const AppChecker({super.key, required this.child});

  final Widget child;

  @override
  State<AppChecker> createState() => _AppCheckerState();
}

class _AppCheckerState extends State<AppChecker> {
  bool _isDialogShowing = false;

  AppCheckerState _appCheckerState(AppGlobal global, String appVersion) {
    final globalVersion = parseVersion(global.appVersion!);
    final localVersion = parseVersion(appVersion);

    if (globalVersion.numbers[0] > localVersion.numbers[0]) {
      return AppCheckerState.updateRequired;
    }

    if (globalVersion.numbers[1] > localVersion.numbers[1]) {
      return AppCheckerState.updateRequired;
    }

    if (globalVersion.numbers[2] > localVersion.numbers[2]) {
      return AppCheckerState.updateWarning;
    }

    return AppCheckerState.upToDate;
  }

  Future<void> _handleUpdateWarning(BuildContext context) async {
    if (_isDialogShowing) return;

    final appCubit = context.read<AppCubit>();
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(AppConstants.kUpdateWarningDismissCount) ?? 0;
    print("Update warning count: $count");

    if (count >= AppConstants.kUpdateWarningDismissLimit) return;

    if (!mounted) return;
    _isDialogShowing = true;

    // ignore: use_build_context_synchronously
    final didUpdate = await AppUpdateDialog.show(
      title: 'New Update!',
      message:
          'A new feature is available in the app. Please update to get the latest features.',
      this.context,
      onUpdate: () => appCubit.getGlobal(),
    );

    _isDialogShowing = false;

    if (!mounted) return;

    if (didUpdate != true) {
      await prefs.setInt(AppConstants.kUpdateWarningDismissCount, count + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listener: (context, state) {
        state.whenOrNull(
          loaded: (global, appVersion) {
            final checkerState = _appCheckerState(global, appVersion);
            if (checkerState == AppCheckerState.upToDate) {
              return;
            } else if (checkerState == AppCheckerState.updateRequired) {
              final _ = AppUpdateDialog.show(
                title: 'Update Required',
                isDismissable: false,
                message:
                    'A new version of the app is available. Please update to continue using Coffix.',
                context,
                onUpdate: () {
                  context.read<AppCubit>().getGlobal();
                },
              );
            } else if (checkerState == AppCheckerState.updateWarning) {
              print("This is true");
              _handleUpdateWarning(context);
            }
          },
        );
      },
      builder: (context, state) {
        return widget.child;
      },
    );
  }
}
