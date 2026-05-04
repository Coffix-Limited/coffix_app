import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailForgotPasswordSent extends StatelessWidget {
  const EmailForgotPasswordSent({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 128),
      child: Container(
        padding: AppSizes.defaultPadding,
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            SizedBox(height: AppSizes.xl),
            Text("Check your email", style: AppTypography.titleS),
            SizedBox(height: AppSizes.sm),
            Text(
              "A retrieval link has been emailed to you. Please click the link, update your password  and login again",
              style: AppTypography.bodyXS.copyWith(
                color: AppColors.textBlackColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.xl),

            SizedBox(height: AppSizes.xl),
            AppButton(
              onPressed: () {
                context.read<AuthCubit>().goToLogin();
              },
              label: "OK",
            ),

            SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}
