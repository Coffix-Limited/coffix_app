import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/profile/presentation/widgets/confirm_account_deletion.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/organisms/app_layout_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  static String route = 'about_route';
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
      ],
      child: const AboutView(),
    );
  }
}

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    final global = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global) => global,
      orElse: () => null,
    );
    return Scaffold(
      appBar: const AppBackHeader(title: 'About'),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          state.maybeWhen(
            loading: () => const AppLoading(),
            orElse: () => const SizedBox.shrink(),
          );
          return AppLayoutBody(
            child: Padding(
              padding: AppSizes.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'General information',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoRow(
                          label: 'App version',
                          value: global?.appVersion ?? '',
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Last login',
                          value: '${user?.user.lastLogin?.formatDate()}',
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Customer ID',
                          value: user?.user.qrId ?? '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  Center(
                    child: AppButton(
                      onPressed: () {},
                      label: 'Report an issue / feedback',
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  Center(
                    child: AppButton(
                      onPressed: () {
                        if (global?.specialUrl != null) {
                          launchUrl(Uri.parse(global?.specialUrl ?? ''));
                        } else {
                          AppNotification.error(
                            context,
                            'No special URL found',
                          );
                        }
                      },
                      label: 'Coffix website',
                    ),
                  ),
                  Spacer(),
                  Center(
                    child: AppButton(
                      color: AppColors.error,
                      onPressed: () {
                        ConfirmAccountDeletion.show(
                          context,
                          onConfirm: () {
                            context.read<AuthCubit>().deleteAccount();
                            context.read<CartCubit>().resetCart();
                          },
                        );
                      },
                      label: 'Delete account',
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: AppTypography.bodyXS)),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: AppTypography.bodyXS,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
