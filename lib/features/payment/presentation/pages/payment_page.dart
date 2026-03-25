import 'dart:async';

import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:coffix_app/features/payment/logic/payment_cubit.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_successful_page.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

class PaymentPage extends StatelessWidget {
  static String route = 'payment_route';
  const PaymentPage({super.key, required this.paymentRequest});

  final PaymentRequest paymentRequest;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<PaymentCubit>()),
        BlocProvider.value(value: getIt<OrderCubit>()),
      ],
      child: PaymentView(paymentRequest: paymentRequest),
    );
  }
}

class PaymentView extends StatefulWidget {
  const PaymentView({super.key, required this.paymentRequest});

  final PaymentRequest paymentRequest;

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  InAppWebViewController? _webViewController;
  late final StreamController<VoidCallback> _navController;
  late final StreamSubscription<VoidCallback> _navSubscription;
  String? _pendingUrl;

  final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    applePayAPIEnabled: true,
    userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1",
  );

  @override
  void initState() {
    super.initState();
    _navController = StreamController<VoidCallback>();
    _navSubscription = _navController.stream.listen((action) {
      if (mounted) action();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentCubit>().resetPayment();
      initPayment();
    });
  }

  @override
  void dispose() {
    _webViewController = null;
    _navSubscription.cancel();
    _navController.close();
    super.dispose();
  }

  void initPayment() {
    final cart = context.read<CartCubit>().state.cart;
    if (cart == null) return;
    context.read<PaymentCubit>().createPayment(request: widget.paymentRequest);
  }

  NavigationActionPolicy _handleNavigation(String url) {
    print("Navigating to $url");
    final uri = Uri.parse(url);
    final isSuccess = uri.path == '/payment/successful';
    final isCancelled = uri.path == '/payment/cancelled';

    if (isSuccess) {
      _navController.add(() {
        final paymentCubit = context.read<PaymentCubit>();
        final orderId = paymentCubit.state.maybeWhen(
          loaded: (_, order) => order.docId,
          success: (order) => order.docId,
          orElse: () => null,
        );
        if (orderId == null) return;
        final scheduledAt = TimeUtils.now().add(
          Duration(minutes: widget.paymentRequest.duration.toInt()),
        );
        context.read<OrderCubit>().updateOrderTime(
          orderId: orderId,
          scheduledAt: scheduledAt,
        );
        context.read<CartCubit>().resetCart();
        context.goNamed(
          PaymentSuccessfulPage.route,
          extra: {"pickupAt": scheduledAt},
        );
      });
      return NavigationActionPolicy.CANCEL;
    } else if (isCancelled) {
      _navController.add(() {
        context.goNamed(CartPage.route);
      });
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text("Payment", style: theme.textTheme.titleLarge)),
      body: BlocListener<PaymentCubit, PaymentState>(
        listenWhen: (prev, curr) =>
            curr.mapOrNull(loaded: (_) => true) ?? false,
        listener: (context, state) {
          state.maybeWhen(
            loaded: (paymentUrl, _) {
              if (_webViewController != null) {
                _webViewController!.loadUrl(
                  urlRequest: URLRequest(url: WebUri(paymentUrl)),
                );
              } else {
                _pendingUrl = paymentUrl;
              }
            },
            orElse: () {},
          );
        },
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            return state.maybeMap(
              initial: (_) => const SizedBox.shrink(),
              loading: (_) => AppLoading(),
              loaded: (_) => InAppWebView(
                initialSettings: _settings,
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  if (_pendingUrl != null) {
                    controller.loadUrl(
                      urlRequest: URLRequest(url: WebUri(_pendingUrl!)),
                    );
                    _pendingUrl = null;
                  }
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';
                  return _handleNavigation(url);
                },
              ),
              error: (error) => AppError(
                title: "Failed to load payment",
                subtitle: error.message,
              ),
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
