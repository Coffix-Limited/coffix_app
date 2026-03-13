import 'package:coffix_app/features/credit/presentation/pages/credit_successful_page.dart';
import 'package:coffix_app/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CreditTopupPaymentPage extends StatelessWidget {
  static String route = 'credit_topup_payment_route';

  const CreditTopupPaymentPage({super.key, required this.paymentSessionUrl});

  final String paymentSessionUrl;

  @override
  Widget build(BuildContext context) {
    return CreditTopupPaymentView(paymentSessionUrl: paymentSessionUrl);
  }
}

class CreditTopupPaymentView extends StatefulWidget {
  const CreditTopupPaymentView({super.key, required this.paymentSessionUrl});

  final String paymentSessionUrl;

  @override
  State<CreditTopupPaymentView> createState() => _CreditTopupPaymentViewState();
}

class _CreditTopupPaymentViewState extends State<CreditTopupPaymentView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            final isSuccess =
                uri.scheme == 'https' &&
                uri.host == 'www.coffix.co.nz' &&
                (uri.path == '/payment/successful' ||
                    uri.path.contains('/credit') &&
                        uri.path.contains('success'));
            if (isSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.goNamed(ProfilePage.route);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentSessionUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Top up Coffix Credit', style: theme.textTheme.titleLarge),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
