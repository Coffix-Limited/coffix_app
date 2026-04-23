import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/data/model/user_with_store.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/logic/otp_cubit.dart';
import 'package:coffix_app/features/drafts/logic/draft_cubit.dart';
import 'package:coffix_app/features/drafts/presentation/pages/drafts_page.dart';
import 'package:coffix_app/features/home/presentation/widgets/app_checker.dart';
import 'package:coffix_app/features/network/logic/network_cubit.dart';
import 'package:coffix_app/features/network/presentation/widgets/no_internet_connection.dart';
import 'package:coffix_app/features/home/presentation/widgets/email_forgot_password_sent.dart';
import 'package:coffix_app/features/home/presentation/widgets/email_verification_form.dart';
import 'package:coffix_app/features/home/presentation/widgets/forgot_password.dart';
import 'package:coffix_app/features/home/presentation/widgets/login_form.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/features/modifier/logic/modifier_cubit.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/order/presentation/pages/order_page.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/profile/presentation/pages/personal_info_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/profile_page.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_location.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
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
        BlocProvider.value(value: getIt<NetworkCubit>()),
        BlocProvider.value(value: getIt<AppCubit>()),
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<OtpCubit>()),
        BlocProvider.value(value: getIt<StoreCubit>()),
        BlocProvider.value(value: getIt<ProductCubit>()),
        BlocProvider.value(value: getIt<ModifierCubit>()),
        BlocProvider.value(value: getIt<DraftCubit>()),
        BlocProvider.value(value: getIt<OrderCubit>()),
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
  bool _isNoInternetDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppCubit>().getGlobal();
    });
    context.read<AuthCubit>().listenToUser();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user.user,
      orElse: () => null,
    );
    final bool isAuthenticated = user != null;

    return BlocListener<NetworkCubit, NetworkState>(
      listener: (context, state) {
        state.when(
          disconnected: () {
            if (_isNoInternetDialogShowing) return;
            _isNoInternetDialogShowing = true;
            NoInternetConnection.show(context).then((_) {
              _isNoInternetDialogShowing = false;
            });
          },
          connected: () {
            if (_isNoInternetDialogShowing) {
              Navigator.of(context, rootNavigator: true).pop();
              _isNoInternetDialogShowing = false;
            }
          },
        );
      },
      child: AppChecker(
        child: Scaffold(
          backgroundColor: AppColors.black.withValues(
            alpha: isAuthenticated ? 1 : 0.7,
          ),
          body: FormBuilder(
            key: formKey,
            onChanged: () {
              setState(() {
                formKey.currentState?.save();
              });
            },
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: AppSizes.defaultPadding,
                          child: BlocListener<OtpCubit, OtpState>(
                            listenWhen: (prev, curr) => curr.maybeWhen(
                              verified: () => !prev.maybeWhen(
                                verified: () => true,
                                orElse: () => false,
                              ),
                              orElse: () => false,
                            ),
                            listener: (context, _) {
                              context.goNamed(
                                PersonalInfoPage.route,
                                extra: {"canBack": true},
                              );
                            },
                            child: BlocConsumer<AuthCubit, AuthState>(
                              listenWhen: (previous, current) =>
                                  previous != current,
                              listener: (context, state) {
                                state.whenOrNull(
                                  authenticated: (userWithStore) async {
                                    context.read<StoreCubit>().getStores();
                                    context.read<ProductCubit>().getProducts();
                                    context.read<DraftCubit>().getDrafts();
                                    context.read<OrderCubit>().getOrders();
                                    if (userWithStore.user.emailVerified ==
                                            true &&
                                        userWithStore.user.finishedOnboarding !=
                                            true) {
                                      context.goNamed(
                                        PersonalInfoPage.route,
                                        extra: {"canBack": false},
                                      );
                                    }
                                  },
                                  passwordResetEmailSent: () {
                                    AppNotification.show(
                                      context,
                                      'Password reset email sent. Please check your email.',
                                    );
                                  },
                                  unauthenticated: () {
                                    context.goNamed(HomePage.route);
                                  },
                                  error: (message) =>
                                      AppNotification.error(context, message),
                                );
                              },
                              builder: (context, state) {
                                final Widget mainContent = state.when(
                                  emailNotVerified: () =>
                                      EmailVerificationForm(),
                                  hasAccount: (hasAccount) =>
                                      LoginForm(formKey: formKey),
                                  otpSent: (email) =>
                                      LoginForm(formKey: formKey),
                                  forgotPassword: () => ForgotPassword(),
                                  passwordResetEmailSent: () =>
                                      EmailForgotPasswordSent(),
                                  initial: () => AppLoading(),
                                  loading: () =>
                                      const Center(child: AppLoading()),
                                  authenticated: (userWithStore) =>
                                      userWithStore.user.emailVerified == true
                                      ? _HomeContent(user: userWithStore)
                                      : EmailVerificationForm(),
                                  unauthenticated: () =>
                                      LoginForm(formKey: formKey),
                                  error: (message) =>
                                      LoginForm(formKey: formKey),
                                );

                                return state == AuthState.loading()
                                    ? const Center(child: AppLoading())
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Column(
                                                children: [
                                                  Opacity(
                                                    opacity: isAuthenticated
                                                        ? 1
                                                        : 0.3,
                                                    child: SvgPicture.asset(
                                                      AppImages.nameLogo,
                                                      width: 124.0,
                                                      height: 64.0,
                                                    ),
                                                  ),
                                                  if (isAuthenticated)
                                                    const AppLocation(
                                                      color: AppColors.white,
                                                    ),
                                                ],
                                              ),
                                              if (isAuthenticated)
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      if (isAuthenticated &&
                                                          user.emailVerified ==
                                                              true) {
                                                        context.goNamed(
                                                          ProfilePage.route,
                                                        );
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.settings,
                                                      color: Colors.white,
                                                      size: AppSizes
                                                          .iconSizeLarge,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

                                          mainContent,
                                          SizedBox(height: AppSizes.xl),
                                          Spacer(),
                                          Opacity(
                                            opacity: isAuthenticated ? 1 : 0.6,
                                            child: Column(
                                              children: [
                                                AppButton.primary(
                                                  color: AppColors.lightGrey,
                                                  onPressed: () {
                                                    context
                                                        .read<ProductCubit>()
                                                        .initDefaultCategory();
                                                    context.goNamed(
                                                      MenuPage.route,
                                                    );
                                                  },
                                                  label: "New Order",
                                                  disabled:
                                                      isAuthenticated &&
                                                          user.emailVerified ==
                                                              true
                                                      ? false
                                                      : true,
                                                ),
                                                const SizedBox(
                                                  height: AppSizes.md,
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: AppButton.primary(
                                                        onPressed: () async {
                                                          if (isAuthenticated &&
                                                              user.emailVerified ==
                                                                  true) {
                                                            context.pushNamed(
                                                              OrderPage.route,
                                                            );
                                                          }
                                                        },
                                                        label: "ReOrder",
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: AppSizes.md,
                                                    ),
                                                    Expanded(
                                                      child: AppButton.primary(
                                                        onPressed: () {
                                                          if (isAuthenticated &&
                                                              user.emailVerified ==
                                                                  true) {
                                                            context.pushNamed(
                                                              DraftsPage.route,
                                                            );
                                                          }
                                                        },
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
  const _HomeContent({required this.user});

  final AppUserWithStore user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    String displayName =
        user.user.firstName ?? user.user.nickName?.toUpperCase() ?? "";

    if (displayName.length > 15) {
      displayName = '${displayName.substring(0, 15)}...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: screenHeight * 0.1),
        Text(
          "Welcome $displayName",
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        AppIcon.withSvgPath(AppImages.logo, size: AppSizes.iconSizeXXLarge),
      ],
    );
  }
}
