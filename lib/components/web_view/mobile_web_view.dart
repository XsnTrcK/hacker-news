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
  final Future<void> Function(String)? handleOverscroll;
  const MobileWebView(this.url, this._displayReaderMode,
      {Key? key, this.handleOverscroll})
      : super(key: key);

  @override
  State<MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> {
  final RegExp _localStyleRegExp = RegExp('style="[a-zA-Z0-9#:%;\\s-]+"');
  final RegExp _navTagsRegExp = RegExp(r'<nav[a-zA-Z"=\s-]*>.*<\/nav>');
  String _downloadedHtml = '';
  Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers = {
    Factory<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer()),
  };
  late String _readerViewStyle;
  late WebViewController _controller;

  @override
  void initState() {
    _controller = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FLUTTER_CHANNEL', onMessageReceived: (message) {
        if (widget.handleOverscroll != null) {
          widget.handleOverscroll!(message.message);
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          if (!widget._displayReaderMode) {
            final isHorizontalScrollable =
                await _controller.runJavaScriptReturningResult(
                    'window.innerWidth < document.body.scrollWidth;') as bool;
            if (isHorizontalScrollable) {
              await _controller.runJavaScript(
                  '(()=>{var l=!1,s=!0,e=!1;let o=()=>{let o=window.innerWidth+window.scrollX;o>=document.body.scrollWidth?(e=!0,setTimeout(()=>e=!1,1500),l&&window.FLUTTER_CHANNEL.postMessage("nextPage"),l=!l):window.scrollX<=0&&(e=!0,setTimeout(()=>e=!1,1500),s&&window.FLUTTER_CHANNEL.postMessage("previousPage"),s=!s)};window.onscroll=()=>{e||0===window.scrollX||(window.scrollX>0&&s&&(s=!1),o())}})();');
              setState(() {
                _gestureRecognizers = {
                  Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer()),
                  Factory<HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer()),
                };
              });
            }
          }
          if (_downloadedHtml != '') return;
          await _getSimplifiedHtml((html) async {
            if (!widget._displayReaderMode) return;
            await _controller.loadHtmlString(
                "$_readerViewStyle${_removeUnwantedHtml(_downloadedHtml)}",
                baseUrl: widget.url);
          });
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
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
      _controller.loadHtmlString(htmlString, baseUrl: widget.url);
    } else {
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    _readerViewStyle = theme.readerViewStyle;
    _controller.setBackgroundColor(widget._displayReaderMode
        ? theme.scaffoldBackgroundColor
        : Colors.white);

    return WebViewWidget(
      controller: _controller,
      gestureRecognizers: _gestureRecognizers,
    );
  }
}
