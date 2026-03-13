import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final formKey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      onChanged: () {
        setState(() {
          formKey.currentState?.save();
        });
      },
      child: Container(
        padding: AppSizes.defaultPadding,
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            SizedBox(height: AppSizes.xl),
            Text("Forgot your password?", style: AppTypography.titleS),
            Text(
              "Please enter your email address",
              style: AppTypography.body2XS.copyWith(
                color: AppColors.textBlackColor,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            AppField(hintText: "Email", name: "email"),
            SizedBox(height: AppSizes.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AppButton(
                disabled:
                    formKey.currentState?.value["email"] == null ||
                    formKey.currentState?.value["email"] == "",
                onPressed: () {
                  final email = formKey.currentState?.value['email'] as String;
                  context.read<AuthCubit>().forgotPasswordWithEmail(
                    email: email,
                  );
                },
                label: "Retrieve my password",
              ),
            ),
            SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}
