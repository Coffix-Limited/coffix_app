import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/referral/logic/referral_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class CoffeeOnUsPage extends StatelessWidget {
  static String route = 'coffee_on_us_route';
  const CoffeeOnUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ReferralCubit>(),
      child: const CoffeeOnUsView(),
    );
  }
}

class CoffeeOnUsView extends StatefulWidget {
  const CoffeeOnUsView({super.key});

  @override
  State<CoffeeOnUsView> createState() => _CoffeeOnUsViewState();
}

class _CoffeeOnUsViewState extends State<CoffeeOnUsView> {
  static const int _minFriends = 3;

  final _formKey = GlobalKey<FormBuilderState>();
  int _friendCount = _minFriends;
  String? _errorMessage;

  Widget _buildFriendRow(int index) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AppField(
                      hintText: "First Name",
                      name: "firstName_$index",
                      isHorizontalAlign: true,
                    ),
                  ),
                  SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: AppField(
                      hintText: "Last Name",
                      name: "lastName_$index",
                      isHorizontalAlign: true,
                    ),
                  ),
                ],
              ),
            ),
            if (_friendCount > _minFriends)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => setState(() => _friendCount--),
              ),
          ],
        ),
        SizedBox(height: AppSizes.sm),
        AppField(
          hintText: "Email",
          name: "email_$index",
          isHorizontalAlign: true,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
        ),
        if (index < _friendCount - 1) Divider(height: AppSizes.xxl),
      ],
    );
  }

  void _submit(BuildContext context) {
    setState(() => _errorMessage = null);
    _formKey.currentState?.save();

    final fields = _formKey.currentState!.value;
    final recipients = <Map<String, String>>[];
    String? localError;

    for (int i = 0; i < _friendCount; i++) {
      final firstName = (fields['firstName_$i'] as String? ?? '').trim();
      final lastName = (fields['lastName_$i'] as String? ?? '').trim();
      final email = (fields['email_$i'] as String? ?? '').trim();

      final hasFirstName = firstName.isNotEmpty;
      final hasLastName = lastName.isNotEmpty;
      final hasEmail = email.isNotEmpty;

      if (!hasFirstName && !hasLastName && !hasEmail) continue;

      if (hasFirstName && !hasLastName && !hasEmail) {
        localError = 'Please enter an email for friend ${i + 1}';
        break;
      }
      if (!hasFirstName && hasLastName && !hasEmail) {
        localError = 'Please enter a name for friend ${i + 1}';
        break;
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(email)) {
        localError = 'Invalid email for friend ${i + 1}';
        break;
      }

      recipients.add({'name': '$firstName $lastName', 'email': email});
    }

    if (localError != null) {
      setState(() => _errorMessage = localError);
      return;
    }

    if (recipients.isEmpty) {
      setState(
        () => _errorMessage = "Please fill in at least one friend's details",
      );
      return;
    }

    context.read<ReferralCubit>().createReferral(recipients);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ReferralCubit>().state.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
    final global = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global, appVersion) => global,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBackHeader(title: 'Coffee On Us', showLocation: false),
      body: BlocListener<ReferralCubit, ReferralState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (message) {
              _formKey.currentState?.reset();
              AppNotification.show(
                context,
                message.isNotEmpty ? message : 'Referral sent!',
              );
            },
            error: (message) {
              setState(() => _errorMessage = message);
            },
            orElse: () {},
          );
        },
        child: FormBuilder(
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppSizes.defaultPadding,
            child: Column(
              children: [
                Text(
                  "Introduce your friends to the Coffix App and get a coffee on us after their first TopUp (within ${global?.referralExpiryDays?.toInt() ?? 7} days from your invitation)",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.xl),
                ...List.generate(_friendCount, _buildFriendRow),
                SizedBox(height: AppSizes.md),
                // TextButton.icon(
                //   onPressed: () => setState(() => _friendCount++),
                //   icon: const Icon(Icons.add_circle_outline),
                //   label: const Text("Add another friend"),
                // ),
                if (_errorMessage != null) ...[
                  SizedBox(height: AppSizes.sm),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: AppSizes.xl),
                AppButton(
                  disabled: isLoading,
                  onPressed: () => _submit(context),
                  label: isLoading ? "Sending..." : "Invite your friends",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
