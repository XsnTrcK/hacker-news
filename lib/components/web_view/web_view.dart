import 'dart:io';
import 'mobile_web_view.dart';
import 'windows_web_viewer.dart';
import 'package:fluent_ui/fluent_ui.dart';

class WebView extends StatelessWidget {
  final String url;
  final bool _displayReaderMode;

  const WebView(this.url, this._displayReaderMode, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isWindows
        ? WindowsWebView(url)
        : MobileWebView(url, _displayReaderMode);
  }
}
