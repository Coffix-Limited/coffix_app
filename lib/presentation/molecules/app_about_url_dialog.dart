import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AppAboutUrlDialog extends StatefulWidget {
  const AppAboutUrlDialog({super.key, required this.url});

  final String url;

  @override
  State<AppAboutUrlDialog> createState() => _AppAboutUrlDialogState();
}

class _AppAboutUrlDialogState extends State<AppAboutUrlDialog> {
  final _settings = InAppWebViewSettings(javaScriptEnabled: true);

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: widget.url.isNotEmpty
            ? InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings: _settings,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
