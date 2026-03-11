import 'dart:async';

import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/auth/data/model/user_with_store.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/logic/otp_cubit.dart';
import 'package:coffix_app/features/home/presentation/widgets/email_verification_form.dart';
import 'package:coffix_app/features/home/presentation/widgets/home_action_buttons.dart';
import 'package:coffix_app/features/home/presentation/widgets/login_form.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/features/order/presentation/pages/order_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/profile_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_location.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  static String route = 'home_route';
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<OtpCubit>()),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().listenToUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black.withValues(alpha: 0.7),
      body: FormBuilder(
        key: formKey,
        onChanged: () {
          setState(() {
            formKey.currentState?.save();
          });
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: AppSizes.defaultPadding,
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  state.whenOrNull(
                    error: (message) => AppNotification.error(context, message),
                  );
                },
                builder: (context, state) {
                  final Widget mainContent = state.when(
                    emailNotVerified: () => EmailVerificationForm(),
                    hasAccount: (hasAccount) => LoginForm(formKey: formKey),
                    otpSent: (email) => LoginForm(formKey: formKey),
                    initial: () => AppLoading(),
                    loading: () => const Center(child: AppLoading()),
                    authenticated: (userWithStore) =>
                        _HomeContent(user: userWithStore),
                    unauthenticated: () => LoginForm(formKey: formKey),
                    error: (message) => LoginForm(formKey: formKey),
                  );

                  return state == AuthState.loading()
                      ? const Center(child: AppLoading())
                      : Column(
                          children: [
                            Opacity(
                              opacity: 0.3,
                              child: SvgPicture.asset(
                                AppImages.nameLogo,
                                width: 124.0,
                                height: 64.0,
                              ),
                            ),

                            mainContent,
                            Opacity(
                              opacity: 0.6,
                              child: Column(
                                children: [
                                  AppButton.primary(
                                    onPressed: () {
                                      context.goNamed(MenuPage.route);
                                    },
                                    label: "New Order",
                                    disabled: true,
                                  ),
                                  const SizedBox(height: AppSizes.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton.primary(
                                          onPressed: () async {
                                            // context.pushNamed(OrderPage.route);
                                            // await FirebaseAuth.instance
                                            // .signOut();
                                          },
                                          label: "ReOrder",
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.md),
                                      Expanded(
                                        child: AppButton.primary(
                                          onPressed: () {},
                                          label: "My Drafts",
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.user, super.key});

  final AppUserWithStore user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Welcome ${user.user.firstName ?? user.user.nickName ?? ""}",
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        AppIcon.withSvgPath(AppImages.logo, size: AppSizes.iconSizeXXLarge),
        // AppButton.primary(
        //   onPressed: () {
        //     context.goNamed(MenuPage.route);
        //   },
        //   label: "New Order",
        // ),
        // const SizedBox(height: AppSizes.md),
        // Row(
        //   children: [
        //     Expanded(
        //       child: AppButton.primary(
        //         onPressed: () {
        //           context.pushNamed(OrderPage.route);
        //         },
        //         label: "ReOrder",
        //       ),
        //     ),
        //     const SizedBox(width: AppSizes.md),
        //     Expanded(
        //       child: AppButton.primary(
        //         onPressed: () {},
        //         disabled: true,
        //         label: "My Drafts",
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
