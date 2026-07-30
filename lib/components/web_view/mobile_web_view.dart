// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hackernews/components/web_view/web_view_carrier.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart' as material;

class MobileWebView extends StatefulWidget {
  final String url;
  final bool displayReaderMode;
  final bool eager;
  final WebViewCarrier? carrier;
  final void Function(bool isReaderable)? onReadabilityDetermined;

  const MobileWebView(
    this.url,
    this.displayReaderMode, {
    super.key,
    this.eager = true,
    this.carrier,
    this.onReadabilityDetermined,
  });

  @override
  State<MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> {
  late WebViewCarrier _carrier;
  bool _ownsCarrier = false;
  bool canGoBack = false;
  bool _isLoading = true;
  bool _awaitingReaderHtml = false;
  bool _showingReader = false;
  bool _retriedAfterLoadFailure = false;
  late String _readerViewStyle;
  bool _initialRenderChecked = false;
  Timer? _readerHtmlTimeoutTimer;
  BuildContext? _dialogContext;

  String get _resolvedUrl => _carrier.resolvedUrl;

  void _attachCarrier(WebViewCarrier carrier) {
    _ownsCarrier = widget.carrier == null;
    _carrier = carrier;
    _carrier.onHtmlReady = _onCarrierHtmlReady;
    _carrier.onReadabilityDetermined = _onCarrierReadabilityDetermined;
    _carrier.onUrlChanged = _onCarrierUrlChanged;
    _carrier.onLoadComplete = _onCarrierLoadComplete;
    _carrier.onExternalNavigation = _onExternalNavigation;
  }

  void _releaseCurrentCarrier() {
    if (_ownsCarrier) {
      _carrier.dispose();
    } else {
      _carrier.detach();
    }
  }

  void _checkInitialCarrierState() {
    if (_carrier.isReady) {
      final isReaderable = _carrier.cachedIsReaderable!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onReadabilityDetermined?.call(isReaderable);
        }
      });
    }
    _reconcileDisplayState();
  }

  @override
  void initState() {
    super.initState();
    _attachCarrier(widget.carrier ?? WebViewCarrier(url: widget.url));
    _isLoading = !_carrier.isReady;
    canGoBack = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readerViewStyle = FluentTheme.of(context).readerViewStyle;
    if (!_initialRenderChecked) {
      _initialRenderChecked = true;
      _checkInitialCarrierState();
    }
  }

  void _onCarrierHtmlReady() {
    _readerHtmlTimeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _awaitingReaderHtml = false;
    });
  }

  void _onCarrierLoadComplete() {
    if (!mounted) return;
    if (_awaitingReaderHtml) return;
    setState(() => _isLoading = false);
    _reconcileDisplayState();
  }

  void _onCarrierReadabilityDetermined(bool isReaderable) {
    widget.onReadabilityDetermined?.call(isReaderable);
  }

  String _stripFragment(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.removeFragment().toString();
  }

  void _onCarrierUrlChanged(UrlChange change) {
    if (!mounted) return;
    final newCanGoBack = change.url != null && change.url != _resolvedUrl;
    final strippedChangedUrl =
        change.url == null ? null : _stripFragment(change.url!);
    // Reader mode is sticky and applies to whatever page is currently
    // loaded, including pages reached by tapping links. Distinguish a
    // genuine navigation (the URL now differs from what the carrier's cache
    // is scoped to) from the carrier's own loadReaderHtml()/loadOriginal()
    // call settling back to the same page it already had cached.
    final isSamePageAsCache = strippedChangedUrl != null &&
        strippedChangedUrl == _carrier.extractedForUrl;
    if (!isSamePageAsCache) {
      // The reader HTML that may have been showing is for the page just
      // left, not whatever is loading now. This is also a genuinely new
      // navigation attempt, so give it a fresh chance to retry if it hits
      // the same load-failed-without-result dead end as a previous one.
      _showingReader = false;
      _retriedAfterLoadFailure = false;
    }
    setState(() {
      canGoBack = newCanGoBack;
      if (!isSamePageAsCache && widget.displayReaderMode) {
        // Hold the spinner so the live page never flashes before the new
        // page's own reader-mode result lands, since reader mode is
        // currently on. Harmless no-op if _isLoading is already true.
        _isLoading = true;
      }
    });
  }

  Future<void> _onExternalNavigation(Uri uri) async {
    if (!mounted) return;
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch && Platform.isAndroid) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return ContentDialog(
          title: const Text('Open in external app?'),
          content: const Text('This link wants to open in an external app.'),
          actions: [
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            FilledButton(
              child: const Text('Open'),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
      },
    );
    _dialogContext = null;
    if (confirmed != true) return;
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          const material.SnackBar(content: Text('Could not open the link.')),
        );
      }
    } catch (_) {
      if (mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          const material.SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }

  void _reconcileDisplayState() {
    if (!_carrier.isReady) {
      if (widget.displayReaderMode && _carrier.loadFailedWithoutResult) {
        // The load already concluded (a main-frame error) without ever
        // producing a result — on iOS this happens for a phantom, empty
        // WebResourceError that WKWebView sometimes fires on goBack()
        // restoration, even though the page is actually showing fine and a
        // genuine loadRequest() of the same URL works reliably (confirmed:
        // the same repro never hits this on Android). Since onPageFinished
        // is never coming to clear a spinner here, retry once with a real
        // reload instead of leaving reader mode permanently stuck off for
        // this page. Bounded to one retry so a genuinely broken page can't
        // loop forever.
        if (!_retriedAfterLoadFailure) {
          _retriedAfterLoadFailure = true;
          setState(() => _isLoading = true);
          _carrier.loadOriginal();
        }
        return;
      }
      if (widget.displayReaderMode) {
        // Reader mode is wanted but the carrier hasn't finished analyzing
        // the current page yet (e.g. the user toggled it on right after
        // navigating, before analysis completed). Show the spinner instead
        // of silently doing nothing until _onCarrierLoadComplete calls this
        // again once analysis finishes — that later call clears _isLoading
        // regardless of its outcome, so this can't get stuck.
        setState(() => _isLoading = true);
      }
      return;
    }
    if (widget.displayReaderMode && _carrier.hasReaderHtml) {
      if (_awaitingReaderHtml) return;
      setState(() {
        _awaitingReaderHtml = true;
        _isLoading = true;
      });
      _showingReader = true;
      _readerHtmlTimeoutTimer?.cancel();
      _readerHtmlTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || !_awaitingReaderHtml) return;
        setState(() {
          _isLoading = false;
          _awaitingReaderHtml = false;
        });
      });
      _carrier.loadReaderHtml(_readerViewStyle);
      return;
    }
    if (!widget.displayReaderMode && _showingReader) {
      setState(() {
        _awaitingReaderHtml = false;
        _showingReader = false;
      });
      _carrier.loadOriginal();
    }
  }

  @override
  void didUpdateWidget(covariant MobileWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.carrier, widget.carrier)) {
      _readerHtmlTimeoutTimer?.cancel();
      _releaseCurrentCarrier();
      _attachCarrier(widget.carrier ?? WebViewCarrier(url: widget.url));
      _initialRenderChecked = true;
      setState(() {
        _isLoading = !_carrier.isReady;
        _awaitingReaderHtml = false;
        _showingReader = false;
        _retriedAfterLoadFailure = false;
        canGoBack = false;
      });
      _checkInitialCarrierState();
      return;
    }
    if (oldWidget.displayReaderMode != widget.displayReaderMode) {
      // Keep the carrier's live value in sync so analysis triggered by any
      // later in-page navigation (link clicks) sees the current sticky
      // toggle, not whatever was true when the carrier was first built.
      _carrier.displayReaderMode = widget.displayReaderMode;
      _reconcileDisplayState();
    }
  }

  @override
  void dispose() {
    _readerHtmlTimeoutTimer?.cancel();
    final dialogContext = _dialogContext;
    if (dialogContext != null) {
      try {
        Navigator.of(dialogContext).pop();
      } catch (_) {}
    }
    _releaseCurrentCarrier();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    _carrier.controller.setBackgroundColor(
      widget.displayReaderMode ? theme.scaffoldBackgroundColor : Colors.white,
    );

    return material.Scaffold(
      body: Stack(
        children: [
          WebViewWidget(
            controller: _carrier.controller,
            gestureRecognizers: widget.eager
                ? {Factory(() => EagerGestureRecognizer())}
                : {Factory(() => PanGestureRecognizer())},
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: const Center(child: ProgressBar()),
              ),
            ),
        ],
      ),
      floatingActionButton: canGoBack
          ? material.FloatingActionButton.small(
              onPressed: () {
                _carrier.controller.goBack();
              },
              shape: const CircleBorder(),
              child: const Icon(FluentIcons.back),
            )
          : null,
    );
  }
}
