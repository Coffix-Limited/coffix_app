import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ReferralPage extends StatelessWidget {
  static String route = 'referral_route';
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferralView();
  }
}

class ReferralView extends StatefulWidget {
  const ReferralView({super.key});

  @override
  State<ReferralView> createState() => _ReferralViewState();
}

class _ReferralViewState extends State<ReferralView> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.defaultPadding,
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppBackHeader(title: 'Refer a friend'),
                const SizedBox(height: AppSizes.xxl),
                Text(
                  'Introduce your friends to the Coffix app and get a coffee on us after their first purchase (within 7 days from your invitation)',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.lightGrey,
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
                AppField<String>(
                  name: 'firstName',
                  label: 'First name',
                  hintText: 'First name',
                  isRequired: true,
                  validators: [
                    (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                AppField<String>(
                  name: 'lastName',
                  label: 'Last name',
                  hintText: 'Last name',
                  isRequired: true,
                  validators: [
                    (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                AppField<String>(
                  name: 'email',
                  label: 'Email',
                  hintText: 'Email',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  validators: [FormBuilderValidators.email()],
                ),
                const SizedBox(height: AppSizes.xxl),
                AppButton.primary(
                  onPressed: () {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      // TODO: call referral API
                    }
                  },
                  label: 'Send invite',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
