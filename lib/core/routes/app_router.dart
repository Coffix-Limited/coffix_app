import 'dart:async';

import 'package:coffix_app/features/auth/presentation/pages/verify_email_page.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_page.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_successful_page.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_topup_page.dart';
import 'package:coffix_app/features/credit/presentation/pages/credit_topup_payment_page.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/layout/presentation/pages/layout_page.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/order/presentation/pages/order_page.dart';
import 'package:coffix_app/features/order/presentation/pages/schedule_order_page.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_options_page.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_page.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_successful_page.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:coffix_app/features/products/presentation/pages/add_product_page.dart';
import 'package:coffix_app/features/modifier/presentation/pages/customize_product_page.dart';
import 'package:coffix_app/features/products/presentation/pages/products_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/about_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/personal_info_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/profile_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/qr_id_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/referral_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/share_your_balance_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/special_url_page.dart';
import 'package:coffix_app/features/stores/presentation/pages/stores_page.dart';
import 'package:coffix_app/features/transaction/presentation/pages/transaction_page.dart';
import 'package:coffix_app/features/wrapper/presentation/pages/wrapper_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _authSubscription;

  _GoRouterRefreshStream(Stream<dynamic> authStream) {
    notifyListeners();
    _authSubscription = authStream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: "/home",
    refreshListenable: _GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    // redirect: (context, state) {
    //   final currentUser = FirebaseAuth.instance.currentUser;
    //   print('Current state: ${state.uri.path} - ${currentUser?.uid}');
    //   final isLoggedIn = currentUser != null;
    //   final isOnAuthRoute = state.matchedLocation.startsWith('/auth');

    //   if (!isLoggedIn) {
    //     if (!isOnAuthRoute) return '/auth';
    //     return null;
    //   }

    //   if (isLoggedIn && isOnAuthRoute) return '/';
    //   return null;
    // },
    routes: [
      GoRoute(
        path: "/",
        name: WrapperPage.route,
        builder: (context, state) => const WrapperPage(),
      ),
      // GoRoute(
      //   path: "/auth",
      //   name: LoginPage.route,
      //   builder: (context, state) => const LoginPage(),
      //   routes: [
      //     GoRoute(
      //       path: "create-account",
      //       name: CreateAccountPage.route,
      //       builder: (context, state) => const CreateAccountPage(),
      //     ),
      //   ],
      // ),

      // WHEN USER IS LOGGED IN
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            LayoutPage(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/home",
                name: HomePage.route,
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: "/profile",
                    name: ProfilePage.route,
                    builder: (context, state) => const ProfilePage(),
                    routes: [
                      GoRoute(
                        path: "/personal-info",
                        name: PersonalInfoPage.route,
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          final canBack = extra?['canBack'] as bool? ?? true;
                          return PersonalInfoPage(canBack: canBack);
                        },
                        routes: [],
                      ),
                      GoRoute(
                        path: "/share-your-balance",
                        name: ShareYourBalancePage.route,
                        builder: (context, state) =>
                            const ShareYourBalancePage(),
                      ),
                      GoRoute(
                        path: "/about",
                        name: AboutPage.route,
                        builder: (context, state) => const AboutPage(),
                      ),
                      GoRoute(
                        path: "/qr-id",
                        name: QrIdPage.route,
                        builder: (context, state) => const QrIdPage(),
                      ),
                      GoRoute(
                        path: "/special-url",
                        name: SpecialUrlPage.route,
                        builder: (context, state) => const SpecialUrlPage(),
                      ),
                      GoRoute(
                        path: "/referral",
                        name: ReferralPage.route,
                        builder: (context, state) => const ReferralPage(),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: "/verify-email",
                name: VerifyEmailPage.route,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final email = extra['email'] as String;
                  return VerifyEmailPage(email: email);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/coffix-credit",
                name: CreditPage.route,
                builder: (context, state) => const CreditPage(),
              ),
              GoRoute(
                path: "/credit-topup",
                name: CreditTopupPage.route,
                builder: (context, state) => const CreditTopupPage(),
              ),
              GoRoute(
                path: "/credit-topup-payment",
                name: CreditTopupPaymentPage.route,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final paymentSessionUrl =
                      extra['paymentSessionUrl'] as String;
                  return CreditTopupPaymentPage(
                    paymentSessionUrl: paymentSessionUrl,
                  );
                },
              ),
              GoRoute(
                path: "/credit-success",
                name: CreditSuccessfulPage.route,
                builder: (context, state) => const CreditSuccessfulPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/menu",
                name: MenuPage.route,
                builder: (context, state) => const MenuPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/stores",
                name: StoresPage.route,
                builder: (context, state) => const StoresPage(),
              ),
              GoRoute(
                path: "/products",
                name: ProductsPage.route,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final storeId = extra['storeId'] as String;
                  return ProductsPage(storeId: storeId);
                },
                routes: [
                  GoRoute(
                    path: "add",
                    name: AddProductPage.route,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final product = extra?['product'] as Product;
                      final storeId = extra?['storeId'] as String;
                      final cartItem = extra?['cartItem'] as CartItem?;
                      return AddProductPage(
                        product: product,
                        storeId: storeId,
                        cartItem: cartItem,
                      );
                    },
                  ),
                ],
              ),

              GoRoute(
                path: "/customize-product",
                name: CustomizeProductPage.route,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final product = extra['product'] as Product;
                  final storeId = extra['storeId'] as String;
                  return CustomizeProductPage(
                    product: product,
                    storeId: storeId,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/cart",
                name: CartPage.route,
                builder: (context, state) => const CartPage(),
              ),
              GoRoute(
                path: "/order",
                name: OrderPage.route,
                builder: (context, state) => const OrderPage(),
              ),
              GoRoute(
                path: "/payment-options",
                name: PaymentOptionsPage.route,
                builder: (context, state) => const PaymentOptionsPage(),
              ),
              GoRoute(
                path: "/payment",
                name: PaymentPage.route,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final paymentRequest =
                      extra['paymentRequest'] as PaymentRequest;
                  return PaymentPage(paymentRequest: paymentRequest);
                },
              ),
              GoRoute(
                path: "/payment-successful",
                name: PaymentSuccessfulPage.route,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final pickupAt = extra["pickupAt"] as DateTime;
                  return PaymentSuccessfulPage(pickupAt: pickupAt);
                },
              ),

              GoRoute(
                path: "/schedule-order",
                name: ScheduleOrderPage.route,
                builder: (context, state) => const ScheduleOrderPage(),
              ),
              GoRoute(
                path: "/transactions",
                name: TransactionPage.route,
                builder: (context, state) => const TransactionPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
