import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CoffeeForHomePage extends StatelessWidget {
  static String route = 'coffee_for_home_route';
  const CoffeeForHomePage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CoffeeForHomeView(url: url);
  }
}

class CoffeeForHomeView extends StatefulWidget {
  const CoffeeForHomeView({super.key, required this.url});

  final String url;

  @override
  State<CoffeeForHomeView> createState() => _CoffeeForHomeViewState();
}

class _CoffeeForHomeViewState extends State<CoffeeForHomeView> {
  final _settings = InAppWebViewSettings(javaScriptEnabled: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBackHeader(title: 'Coffee For Home', showLocation: false),
      body: widget.url.isNotEmpty
          ? InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: _settings,
            )
          : const SizedBox.shrink(),
    );
  }
}
