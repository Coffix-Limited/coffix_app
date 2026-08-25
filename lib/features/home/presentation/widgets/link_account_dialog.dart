import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Prompts the user for the password of their existing email/password account
/// so the pending SSO provider (Google/Apple) can be linked to the same
/// Firebase user instead of creating a duplicate account.
class LinkAccountDialog extends StatefulWidget {
  const LinkAccountDialog({
    super.key,
    required this.email,
    required this.provider,
  });

  final String email;
  final String provider;

  /// Provider IDs ('google.com' / 'apple.com') mapped to a display name.
  String get _providerName {
    switch (provider) {
      case 'apple.com':
        return 'Apple';
      case 'google.com':
        return 'Google';
      default:
        return 'your account';
    }
  }

  @override
  State<LinkAccountDialog> createState() => _LinkAccountDialogState();
}

class _LinkAccountDialogState extends State<LinkAccountDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _submit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final password = _formKey.currentState!.value['password'] as String;
      context.read<AuthCubit>().linkAccountWithPassword(
        email: widget.email,
        password: password,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.beige,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: AppSizes.defaultPadding,
        child: FormBuilder(
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connect ${widget._providerName}',
                textAlign: TextAlign.center,
                style: AppTypography.titleS,
              ),
              const SizedBox(height: 14.0),
              Text(
                'You already have an account with ${widget.email}. '
                'Enter your password to connect ${widget._providerName} to it.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14.0),
              AppField(
                hintText: 'Password',
                name: 'password',
                obscureText: true,
                isRequired: true,
                autofocus: true,
              ),
              const SizedBox(height: 14.0),
              AppButton(onPressed: _submit, label: 'Connect'),
              const SizedBox(height: 8.0),
              AppButton.outlined(
                onPressed: () => Navigator.of(context).pop(),
                label: 'Cancel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
