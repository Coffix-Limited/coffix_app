import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/profile/presentation/pages/profile_page.dart';
import 'package:coffix_app/features/stores/presentation/pages/stores_page.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppLocation extends StatelessWidget {
  const AppLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return state.maybeWhen(
          authenticated: (user) {
            return AppClickable(
              showSplash: false,
              onPressed: () {
                context.pushNamed(StoresPage.route);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon.withSvgPath(
                    AppImages.location,
                    size: AppSizes.iconSizeMedium,
                  ),
                  if (user.store != null)
                    Text(
                      "${user.store?.name}",
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: AppColors.lightGrey,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.lightGrey,
                        decorationThickness: 1,
                      ),
                    ),
                ],
              ),
            );
          },
          orElse: () {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon.withSvgPath(
                  AppImages.location,
                  size: AppSizes.iconSizeMedium,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
