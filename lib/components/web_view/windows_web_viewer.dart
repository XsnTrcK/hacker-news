import 'package:fluent_ui/fluent_ui.dart';
import 'package:webview_windows/webview_windows.dart';

class WindowsWebView extends StatefulWidget {
  final String url;
  const WindowsWebView(this.url, {super.key});

  @override
  State<WindowsWebView> createState() => _WindowsWebViewState();
}

class _WindowsWebViewState extends State<WindowsWebView> {
  final _controller = WebviewController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _controller.initialize();
    await _controller.loadUrl(widget.url);

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Webview(_controller)
        : const Text("Not Initialized");
  }
}
