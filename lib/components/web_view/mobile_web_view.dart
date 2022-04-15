// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MobileWebView extends StatefulWidget {
  final String url;
  final bool _displayReaderMode;
  const MobileWebView(this.url, this._displayReaderMode, {Key? key})
      : super(key: key);

  @override
  State<MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> {
  final RegExp _localStyleRegExp = RegExp('style="[a-zA-Z0-9#:%;\\s-]+"');
  final RegExp _navTagsRegExp = RegExp(r'<nav[a-zA-Z"=\s-]*>.*<\/nav>');
  bool _isLoading = true;
  String _downloadedHtml = '';
  late String _readerViewStyle;
  late WebViewController _controller;

  // TODO: Move to separate class?
  Future<String?> _runJs(String command) async {
    try {
      return await _controller.runJavascriptReturningResult(command);
    } catch (_) {
      return null;
    }
  }

  // TODO: Move to separate class?
  Future _getSimplifiedHtml() async {
    // Check for class news-article--content--body
    var tempHtml = await _runJs(
        "window.document.getElementsByClassName('news-article--content--body')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }

    // Check for class body-content
    tempHtml = await _runJs(
        "window.document.getElementsByClassName('body-content')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }

    // Check for class article
    tempHtml = await _runJs(
        "window.document.getElementsByClassName('article')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }

    // Check for tag article
    tempHtml = await _runJs(
        "window.document.getElementsByTagName('article')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }

    // Check for class content
    tempHtml = await _runJs(
        "window.document.getElementsByClassName('content')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }

    // Check for id content
    tempHtml =
        await _runJs("window.document.getElementById('content').innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }

    // Check for tag main
    tempHtml = await _runJs(
        "window.document.getElementsByTagName('main')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }

    // Check for id theContent for web archive
    tempHtml =
        await _runJs("window.document.getElementById('theContent').innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return;
    }
  }

  // TODO: Move to separate class?
  String _removeUnwantedHtml(String html) {
    var updatedHtml = html.replaceAllMapped(_localStyleRegExp, (match) => "");
    updatedHtml = updatedHtml.replaceAllMapped(_navTagsRegExp, (match) => "");
    return updatedHtml;
  }

  @override
  void didUpdateWidget(covariant MobileWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_downloadedHtml.isNotEmpty && widget._displayReaderMode) {
      _controller.loadHtmlString(
          "$_readerViewStyle${_removeUnwantedHtml(_downloadedHtml)}",
          baseUrl: widget.url);
    } else {
      _controller.loadUrl(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    _readerViewStyle = theme.readerViewStyle;
    return Stack(
      children: [
        WebView(
          initialUrl: widget.url,
          javascriptMode: JavascriptMode.unrestricted,
          backgroundColor: theme.scaffoldBackgroundColor,
          onPageFinished: (_) async {
            if (!_isLoading) return;
            await _getSimplifiedHtml();
            setState(() {
              _isLoading = false;
              if (_downloadedHtml.isNotEmpty && widget._displayReaderMode) {
                _controller.loadHtmlString(
                    "${theme.readerViewStyle}${_removeUnwantedHtml(_downloadedHtml)}",
                    baseUrl: widget.url);
              }
            });
          },
          onWebViewCreated: (WebViewController webViewController) {
            _controller = webViewController;
          },
          gestureRecognizers: {
            Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer())
          },
        ),
        _isLoading
            ? const ScaffoldPage(
                content: Center(child: ProgressBar()),
              )
            : const SizedBox.shrink()
      ],
    );
  }
}
