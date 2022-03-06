import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MobileWebView extends StatelessWidget {
  final String url;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  MobileWebView(this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: url,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        _controller.complete(webViewController);
      },
    );
  }
}
