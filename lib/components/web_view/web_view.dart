import 'dart:io';
import 'mobile_web_view.dart';
import 'windows_web_viewer.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'web_view_carrier.dart';

class WebView extends StatelessWidget {
  final String url;
  final bool displayReaderMode;
  final bool eager;
  final WebViewCarrier? carrier;
  final void Function(bool isReaderable)? onReadabilityDetermined;

  const WebView(
    this.url,
    this.displayReaderMode, {
    super.key,
    this.eager = true,
    this.carrier,
    this.onReadabilityDetermined,
  });

  @override
  Widget build(BuildContext context) {
    return Platform.isWindows
        ? WindowsWebView(url)
        : MobileWebView(
            url,
            displayReaderMode,
            eager: eager,
            carrier: carrier,
            onReadabilityDetermined: onReadabilityDetermined,
          );
  }
}
