import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/profile/presentation/widgets/confirm_account_deletion.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_text_button.dart';
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
    final user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    final global = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global, appVersion) => global,
      orElse: () => null,
    );
    final appVersion = context.watch<AppCubit>().state.maybeWhen(
      loaded: (global, appVersion) => appVersion,
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
                    style: AppTypography.bodyM.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "App Version: ${appVersion ?? ""}",
                        style: AppTypography.bodyXS.copyWith(
                          color: AppColors.textBlackColor,
                        ),
                      ),
                      Text(
                        "Last login: ${user?.user.lastLogin?.formatDate()}",
                        style: AppTypography.bodyXS.copyWith(
                          color: AppColors.textBlackColor,
                        ),
                      ),
                      Text(
                        "Customer ID: ${user?.user.qrId ?? ""}",
                        style: AppTypography.bodyXS.copyWith(
                          color: AppColors.textBlackColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xxxxxl),
                  Divider(color: AppColors.textBlackColor),
                  SizedBox(height: AppSizes.xl),
                  AppTextButton(
                    showUnderline: true,
                    onPressed: () async {
                      final String subject = "${user?.user.qrId} - Feedback";
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@coffix.co.nz',
                        queryParameters: {
                          'subject': subject,
                          // optionally add body
                          // 'body': 'Describe your issue here...'
                        },
                      );
                      final launched = await launchUrl(
                        emailUri,
                        mode: LaunchMode.externalApplication,
                      );

                      if (!launched) {
                        throw Exception('No email app found');
                      }
                    },
                    text: 'Report an issue / feedback',
                  ),
                  SizedBox(height: AppSizes.sm),
                  AppTextButton(
                    showUnderline: true,
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse(
                          'https://www.coffix.co.nz/term-of-use-privacy',
                        ),
                      );
                    },
                    text: 'Terms of use & privacy',
                  ),
                  SizedBox(height: AppSizes.sm),
                  AppTextButton(
                    showUnderline: true,
                    onPressed: () {
                      if (global?.specialUrl != null) {
                        launchUrl(Uri.parse(global?.specialUrl ?? ''));
                      } else {
                        AppNotification.error(context, 'No special URL found');
                      }
                    },
                    text: 'Coffix website',
                  ),
                  Spacer(),
                  Center(
                    child: AppTextButton(
                      showUnderline: true,
                      onPressed: () {
                        ConfirmAccountDeletion.show(
                          context,
                          onConfirm: () {
                            LogService().deleteAccount();
                            context.read<AuthCubit>().deleteAccount();
                            context.read<CartCubit>().resetCart();
                          },
                        );
                      },
                      text: 'Delete account',
                      textStyle: AppTypography.bodyS.copyWith(
                        color: AppColors.redColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.redColor,
                      ),
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
