// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart' as material;

class MobileWebView extends StatefulWidget {
  final String _url;
  final bool _displayReaderMode;
  final bool eager;

  const MobileWebView(this._url, this._displayReaderMode,
      {super.key, this.eager = true});

  @override
  State<MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> {
  final RegExp _localStyleRegExp = RegExp('style="[a-zA-Z0-9#:%;\\s-]+"');
  final RegExp _navTagsRegExp = RegExp(r'<nav[a-zA-Z"=\s-]*>.*<\/nav>');
  String _downloadedHtml = '';
  bool canGoBack = false;
  late String _readerViewStyle;
  late WebViewController _controller;

  String get url {
    if (widget._url.startsWith('http:')) {
      return widget._url.replaceFirst("http:", "https:");
    }
    return widget._url;
  }

  @override
  void initState() {
    _controller = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          if (_downloadedHtml != '') return;
          await _getSimplifiedHtml((html) async {
            if (!widget._displayReaderMode) return;
            await _controller.loadHtmlString(
                "$_readerViewStyle${_removeUnwantedHtml(_downloadedHtml)}",
                baseUrl: url);
          });
        },
        onUrlChange: (urlChange) {
          setState(() {
            canGoBack = urlChange.url != null && urlChange.url != url;
          });
        },
      ))
      ..loadRequest(Uri.parse(url));
    super.initState();
  }

  // TODO: Move to separate class?
  Future<String?> _runJs(String command) async {
    try {
      return await _controller.runJavaScriptReturningResult(command) as String?;
    } catch (_) {
      return null;
    }
  }

  // TODO: Move to separate class?
  Future _getSimplifiedHtml(
      Future Function(String html) updateController) async {
    // Check for class news-article--content--body
    var tempHtml = await _runJs(
        "window.document.getElementsByClassName('news-article--content--body')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
    }

    // Check for class body-content
    tempHtml = await _runJs(
        "window.document.getElementsByClassName('body-content')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
    }

    // Check for class article
    tempHtml = await _runJs(
        "window.document.getElementsByClassName('article')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
    }

    // Check for tag article
    tempHtml = await _runJs(
        "window.document.getElementsByTagName('article')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
    }

    // Check for class content
    tempHtml = await _runJs(
        "window.document.getElementsByClassName('content')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
    }

    // Check for id content
    tempHtml =
        await _runJs("window.document.getElementById('content').innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
    }

    // Check for tag main
    tempHtml = await _runJs(
        "window.document.getElementsByTagName('main')[0].innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
    }

    // Check for id theContent for web archive
    tempHtml =
        await _runJs("window.document.getElementById('theContent').innerHTML;");
    if (tempHtml?.isNotEmpty ?? false) {
      _downloadedHtml = tempHtml!;
      return await updateController(_downloadedHtml);
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
    if (oldWidget._displayReaderMode == widget._displayReaderMode ||
        _downloadedHtml.isEmpty) {
      return;
    }
    if (widget._displayReaderMode) {
      final htmlString =
          "$_readerViewStyle${_removeUnwantedHtml(_downloadedHtml)}";
      _controller.loadHtmlString(htmlString, baseUrl: url);
    } else {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    _readerViewStyle = theme.readerViewStyle;
    _controller.setBackgroundColor(widget._displayReaderMode
        ? theme.scaffoldBackgroundColor
        : Colors.white);

    return material.Scaffold(
      body: WebViewWidget(
        controller: _controller,
        gestureRecognizers: widget.eager
            ? {Factory(() => EagerGestureRecognizer())}
            : {Factory(() => PanGestureRecognizer())},
      ),
      floatingActionButton: canGoBack
          ? material.FloatingActionButton.small(
              onPressed: () {
                _controller.goBack();
              },
              shape: CircleBorder(),
              child: const Icon(FluentIcons.back),
            )
          : null,
    );
  }
}
