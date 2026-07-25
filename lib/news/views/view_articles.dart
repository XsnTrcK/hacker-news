import 'package:fluent_ui/fluent_ui.dart';
import 'package:hackernews/components/web_view/web_view_carrier.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/views/display_article.dart';

class ViewArticles extends StatefulWidget {
  final List<TitledItem> _articles;
  final int? initialIndex;

  const ViewArticles(this._articles, {super.key, this.initialIndex});

  @override
  State<ViewArticles> createState() => _ViewArticlesState();
}

class _ViewArticlesState extends State<ViewArticles> {
  static const int _preloadRange = 1;

  late final PageController _pageController;
  final Map<int, WebViewCarrier> _carriers = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget._articles.isEmpty
        ? 0
        : (widget.initialIndex ?? 0).clamp(0, widget._articles.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _ensureCarriersFor(_currentIndex);
  }

  String? _articleUrl(TitledItem item) {
    if (item is StoryItem) {
      final url = item.url;
      return url.isEmpty ? null : url;
    }
    return null;
  }

  void _ensureCarriersFor(int current) {
    if (widget._articles.isEmpty) return;
    final start = (current - _preloadRange).clamp(0, widget._articles.length - 1);
    final end = (current + _preloadRange)
        .clamp(0, widget._articles.length - 1);

    for (int i = start; i <= end; i++) {
      if (_carriers.containsKey(i)) continue;
      final url = _articleUrl(widget._articles[i]);
      if (url == null) continue;
      _carriers[i] = WebViewCarrier(
        url: url,
        displayReaderMode: widget._articles[i].state.displayReaderMode,
      );
    }

    _carriers.removeWhere((idx, carrier) {
      if (idx >= start && idx <= end) return false;
      carrier.dispose();
      return true;
    });
  }

  void _onPageChanged(int idx) {
    setState(() {
      _currentIndex = idx;
    });
    _ensureCarriersFor(idx);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget._articles.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        return DisplayArticle(
          widget._articles[index],
          carrier: _carriers[index],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final carrier in _carriers.values) {
      carrier.dispose();
    }
    _carriers.clear();
    super.dispose();
  }
}
