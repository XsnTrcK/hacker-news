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

  // Mutable (not constructor-only): the caller keeps this in sync with the
  // current sticky reader-mode toggle as it changes, so that analysis
  // triggered by later in-page navigation (link clicks) reflects the latest
  // value rather than whatever was true when the carrier was first built.
  bool? displayReaderMode;

  late final Future<void> _bundleReady;
  String _readabilityBundle = '';
  String? cachedReaderHtml;
  bool? cachedIsReaderable;
  String? _extractedForUrl;
  // Set when the current load attempt concluded (via onWebResourceError)
  // without ever producing a readability result — distinct from
  // cachedIsReaderable, which stays null (not false) in that case so a
  // load error can never flip toggle visibility. Consulted only to stop a
  // caller from waiting indefinitely for a determination that isn't coming.
  bool _loadFailedWithoutResult = false;
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

  // Exposed so MobileWebView can tell whether a reported URL change is a
  // genuine navigation to a different page versus the carrier's own
  // loadReaderHtml()/loadOriginal() call settling back to the same page.
  String? get extractedForUrl => _extractedForUrl;

  // Whether the current load attempt already concluded without a
  // readability result (a main-frame load error). Callers that want reader
  // mode should stop waiting/spinning once this is true, since no
  // onPageFinished is coming for this attempt.
  bool get loadFailedWithoutResult => _loadFailedWithoutResult;

  // Whether a determination's URL is for the carrier's own resolvedUrl,
  // rather than a page reached via a link — used to gate
  // onReadabilityDetermined so it only ever reports the original article's
  // result, keyed on URL identity (stable for the carrier's lifetime)
  // rather than call order.
  bool _isOwnUrl(String? strippedUrl) =>
      strippedUrl != null && strippedUrl == _stripFragment(resolvedUrl);

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
          _onPageFinished(url);
        },
        onWebResourceError: (error) {
          // iOS + Android: when the main frame fails (SSL error, ATS block,
          // network timeout) onPageFinished never fires, leaving _isLoading
          // stuck if nothing clears it. Only clear the spinner here — do NOT
          // declare the page non-readable. A load failure is not a
          // determination about the page's *content*: if this URL was
          // already known to be readerable from an earlier successful load
          // (e.g. a transient/spurious main-frame error while re-navigating
          // back to the article), asserting `false` here would wrongly hide
          // the toggle for a page that genuinely is readerable.
          if (error.isForMainFrame == false) return;
          if (!isReady) {
            _loadFailedWithoutResult = true;
            onLoadComplete?.call();
          }
        },
        onUrlChange: (change) {
          // Invalidate eagerly, at navigation-start, not just in
          // _onPageFinished (load-complete). onUrlChanged below can
          // synchronously trigger MobileWebView's display logic well before
          // the new page's own onPageFinished has a chance to invalidate a
          // stale cache — without this, that logic could act on the
          // previous page's cache.
          final changedUrl = change.url;
          if (changedUrl != null) {
            final stripped = _stripFragment(changedUrl);
            final willInvalidate = _extractedForUrl != stripped;
            if (willInvalidate) {
              cachedReaderHtml = null;
              cachedIsReaderable = null;
              _extractedForUrl = null;
              _loadFailedWithoutResult = false;
            }
          }
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

  String _stripFragment(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.removeFragment().toString();
  }

  Future<void> _onPageFinished(String loadedUrl) async {
    final strippedLoadedUrl = _stripFragment(loadedUrl);
    // The cache is only valid for the URL it was extracted from. If a
    // different page just finished loading (e.g. the user clicked a link
    // inside reader-mode HTML), any existing cache — including one left
    // behind by onWebResourceError, which doesn't track _extractedForUrl —
    // belongs to the wrong page and must not short-circuit analysis below.
    if (_extractedForUrl != strippedLoadedUrl) {
      cachedReaderHtml = null;
      cachedIsReaderable = null;
      _extractedForUrl = null;
      _loadFailedWithoutResult = false;
    }
    if (cachedReaderHtml != null || cachedIsReaderable == false) {
      return;
    }
    if (_analysisInProgress) {
      return;
    }
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
          _extractedForUrl = strippedLoadedUrl;
          _loadFailedWithoutResult = false;
          // Only report through this callback for the carrier's own URL —
          // see _isOwnUrl for why this is gated on identity rather than
          // being unconditional.
          if (_isOwnUrl(strippedLoadedUrl)) {
            onReadabilityDetermined?.call(false);
          }
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
      _extractedForUrl = strippedLoadedUrl;
      _loadFailedWithoutResult = false;
      if (_isOwnUrl(strippedLoadedUrl)) {
        onReadabilityDetermined?.call(html != null);
      }
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
    // baseUrl must match the page this HTML was actually extracted from —
    // not always resolvedUrl, since the webview may have since navigated
    // away from the carrier's own URL — so relative links/images resolve
    // against the right site.
    await controller.loadHtmlString(wrapped,
        baseUrl: _extractedForUrl ?? resolvedUrl);
  }

  Future<void> loadOriginal() async {
    // Reload whatever page the cache is currently scoped to, not always the
    // carrier's own resolvedUrl — the webview may have navigated to a
    // different page since. Captured before any reset below, since a reset
    // clears _extractedForUrl.
    final targetUrl = _extractedForUrl ?? resolvedUrl;
    if (cachedReaderHtml == null) {
      // Nothing successful to reuse (never analyzed, or the last attempt
      // failed) — clear defensively so the next onPageFinished retries.
      cachedIsReaderable = null;
      _extractedForUrl = null;
    }
    await controller.loadRequest(Uri.parse(targetUrl));
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
