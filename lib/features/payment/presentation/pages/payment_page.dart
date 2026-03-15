import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:coffix_app/features/payment/logic/payment_cubit.dart';
import 'package:coffix_app/features/payment/presentation/pages/payment_successful_page.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late WebViewController _webViewController;

  @override
  initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1",
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            print("Navigating to ${request.url}");
            final uri = Uri.parse(request.url);
            // Use path match, ignore query params
            final isSuccess = uri.path == '/payment/successful';

            if (isSuccess) {
              // IMPORTANT: prevent first
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                context.read<CartCubit>().resetCart();
                context.goNamed(
                  PaymentSuccessfulPage.route,
                  extra: {
                    "pickupAt": DateTime.now().add(
                      Duration(minutes: widget.paymentRequest.duration.toInt()),
                    ),
                  },
                );
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentCubit>().resetPayment();
      initPayment();
    });
  }

  void initPayment() {
    final cart = context.read<CartCubit>().state.cart;
    if (cart == null) return;
    context.read<PaymentCubit>().createPayment(request: widget.paymentRequest);
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
            loaded: (paymentUrl) =>
                _webViewController.loadRequest(Uri.parse(paymentUrl)),
            orElse: () {},
          );
        },
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            return state.maybeMap(
              initial: (_) => const SizedBox.shrink(),
              loading: (_) => AppLoading(),
              loaded: (_) => WebViewWidget(controller: _webViewController),
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
