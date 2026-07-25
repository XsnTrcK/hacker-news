import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewCarrier {
  final String url;
  final WebViewController controller;

  static final RegExp _localStyleRegExp =
      RegExp('style="[a-zA-Z0-9#:%;\\s-]+"');

  final bool? displayReaderMode;

  late final Future<void> _bundleReady;
  String _readabilityBundle = '';
  String? cachedReaderHtml;
  bool? cachedIsReaderable;
  bool _analysisInProgress = false;
  bool _loadCompleteFired = false;
  bool _isDisposed = false;
  void Function(bool isReaderable)? onReadabilityDetermined;
  void Function(UrlChange change)? onUrlChanged;
  void Function()? onHtmlReady;
  void Function()? onLoadComplete;
  void Function(Uri uri)? onExternalNavigation;

  WebViewCarrier({required this.url, this.displayReaderMode})
      : controller = WebViewController() {
    _bootstrap();
  }

  String get resolvedUrl =>
      url.startsWith('http:') ? url.replaceFirst('http:', 'https:') : url;

  bool get isReady => cachedIsReaderable != null;

  bool get hasReaderHtml => cachedReaderHtml != null;

  void _bootstrap() {
    _bundleReady =
        rootBundle.loadString('assets/readability-bundle.js').then((js) {
      _readabilityBundle = js;
    });
    if (Platform.isIOS) {
      controller.setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      );
    }
    controller
      ..removeJavaScriptChannel('ReaderReady')
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ReaderReady',
        onMessageReceived: (_) {
          onHtmlReady?.call();
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          // WKWebView issues internal navigations to `about:blank` (view
          // initialization, before the real `loadRequest` target loads) and
          // `about:srcdoc` (sandboxed iframes with a `srcdoc` attribute).
          // Neither is a real external link — let them through as normal
          // navigation instead of prompting the external-app dialog.
          if (uri != null && uri.scheme == 'about') {
            return NavigationDecision.navigate;
          }
          if (uri != null && uri.scheme != 'http' && uri.scheme != 'https') {
            onExternalNavigation?.call(uri);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (url) {
          _onPageFinished();
        },
        onWebResourceError: (error) {
          // iOS + Android: when the main frame fails (SSL error, ATS block,
          // network timeout) onPageFinished never fires, leaving _isLoading
          // stuck. Mark the page non-readable and clear the spinner.
          if (error.isForMainFrame == false) return;
          if (!isReady) {
            cachedIsReaderable = false;
            onReadabilityDetermined?.call(false);
            onLoadComplete?.call();
          }
        },
        onUrlChange: (change) {
          onUrlChanged?.call(change);
        },
      ))
      ..loadRequest(Uri.parse(resolvedUrl));
  }

  Future<String?> _runJs(String command) async {
    try {
      final result = await controller
          .runJavaScriptReturningResult(command)
          .timeout(const Duration(seconds: 10));
      return result.toString();
    } catch (_) {
      return null;
    }
  }

  void _fireLoadComplete() {
    if (_loadCompleteFired) return;
    _loadCompleteFired = true;
    onLoadComplete?.call();
  }

  Future<void> _onPageFinished() async {
    if (cachedReaderHtml != null || cachedIsReaderable == false) return;
    if (_analysisInProgress) return;
    _analysisInProgress = true;
    _loadCompleteFired = false;

    try {
      // Clear the spinner early when reader mode is off — readability analysis continues
      // in the background so the toggle button can still appear if the article is readable.
      if (displayReaderMode == false) {
        _fireLoadComplete();
      }

      await _bundleReady;

      if (_isDisposed) return;
      // Re-check after await — a redirect may have already populated these before the bundle loaded.
      if (cachedReaderHtml != null || cachedIsReaderable == false) return;

      await _runJs(_readabilityBundle);

      if (_isDisposed) return;

      if (displayReaderMode == null) {
        final isReaderable = await _runJs('isProbablyReaderable(document)');
        if (_isDisposed) return;
        if (isReaderable != 'true') {
          cachedIsReaderable = false;
          onReadabilityDetermined?.call(false);
          _fireLoadComplete();
          return;
        }
      }

      final jsonStr = await _runJs(
          'JSON.stringify(new Readability(document.cloneNode(true)).parse())');
      if (_isDisposed) return;
      // Re-check after await — onWebResourceError may have already resolved
      // this page's readability state while the parse was still in flight.
      if (cachedReaderHtml != null || cachedIsReaderable == false) return;
      String? html;
      if (jsonStr != null && jsonStr != 'null') {
        try {
          var decoded = jsonDecode(jsonStr);
          if (decoded is String) decoded = jsonDecode(decoded);
          final parsed = decoded as Map<String, dynamic>?;
          final content = parsed?['content'] as String?;
          if (content?.isNotEmpty ?? false) {
            final title = parsed?['title'] as String? ?? '';
            final byline = parsed?['byline'] as String? ?? '';
            final header =
                '<h1>$title</h1>${byline.isNotEmpty ? '<p>$byline</p>' : ''}';
            html = '$header$content';
          }
        } catch (_) {}
      }

      if (html != null) cachedReaderHtml = html;
      cachedIsReaderable = html != null;
      onReadabilityDetermined?.call(html != null);
      _fireLoadComplete();
    } finally {
      // Reset so a later, non-concurrent invocation (e.g. after loadOriginal()
      // resets the cached fields for a retry) isn't blocked by this guard forever.
      _analysisInProgress = false;
    }
  }

  Future<void> loadReaderHtml(String readerViewStyle) async {
    final html = cachedReaderHtml;
    if (html == null) return;
    final wrapped = '<!DOCTYPE html>'
        '<html><head>'
        '<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">'
        '$readerViewStyle'
        '</head><body>'
        // Strip inline style="" attrs from Readability output — they carry over
        // from the source page and would override the injected reader theme CSS.
        '${_stripStyle(html)}'
        '</body></html>'
        "<script>window.ReaderReady.postMessage('ready');</script>";
    await controller.loadHtmlString(wrapped, baseUrl: resolvedUrl);
  }

  Future<void> loadOriginal() async {
    cachedIsReaderable = null;
    cachedReaderHtml = null;
    await controller.loadRequest(Uri.parse(resolvedUrl));
  }

  String _stripStyle(String html) =>
      html.replaceAllMapped(_localStyleRegExp, (match) => '');

  void detach() {
    onHtmlReady = null;
    onReadabilityDetermined = null;
    onUrlChanged = null;
    onLoadComplete = null;
    onExternalNavigation = null;
  }

  void dispose() {
    _isDisposed = true;
    detach();
    controller.removeJavaScriptChannel('ReaderReady');
  }
}
