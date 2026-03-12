import 'package:hackernews/models/item.dart' show TitledItem;
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/apis/rss_api.dart';
import 'package:hackernews/rss/models/rss_feed.dart';

class CombinedNewsApiRetriever extends NewsApi {
  final NewsApiRetriever _hnApi;
  final RssApiRetriever _rssApi;
  List<TitledItem> _cachedRssItems = [];
  List<TitledItem> _hnItemsFetched = [];
  bool _hnExhausted = false;
  FeedMode _feedMode = FeedMode.all;
  RssFeedInfo? _rssFeedFilter;

  CombinedNewsApiRetriever(this._hnApi, this._rssApi) : super(httpClient);

  void setMode(FeedMode mode, {RssFeedInfo? rssFeedFilter}) {
    _feedMode = mode;
    _rssFeedFilter = rssFeedFilter;
  }

  @override
  Future<void> refresh(NewsType newsType) async {
    _hnItemsFetched = [];
    _hnExhausted = false;
    switch (_feedMode) {
      case FeedMode.all:
        await Future.wait([
          _hnApi.refresh(newsType),
          _rssApi
              .fetchAllFeeds()
              .then((items) => _cachedRssItems = List<TitledItem>.from(items)),
        ]);
      case FeedMode.hn:
        await _hnApi.refresh(newsType);
        _cachedRssItems = [];
      case FeedMode.rss:
        final items = _rssFeedFilter != null
            ? await _rssApi.fetchFeed(_rssFeedFilter!)
            : await _rssApi.fetchAllFeeds();
        _cachedRssItems = List<TitledItem>.from(items);
    }
    if (_cachedRssItems.isNotEmpty) {
      _cachedRssItems.sort((a, b) => b.time.compareTo(a.time));
    }
  }

  @override
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0}) async {
    switch (_feedMode) {
      case FeedMode.rss:
        if (offset >= _cachedRssItems.length) return [];
        return _cachedRssItems.sublist(
            offset, (offset + count).clamp(0, _cachedRssItems.length));
      case FeedMode.hn:
        return _hnApi.getNews(newsType, count: count, offset: offset);
      case FeedMode.all:
        if (!_hnExhausted) {
          final hnItems = await _hnApi.getNews(newsType,
              count: count, offset: _hnItemsFetched.length);
          if (hnItems.isEmpty) {
            _hnExhausted = true;
          } else {
            _hnItemsFetched.addAll(hnItems);
          }
        }
        final pool = <TitledItem>[..._cachedRssItems, ..._hnItemsFetched];
        pool.sort((a, b) => b.time.compareTo(a.time));
        if (offset >= pool.length) return [];
        return pool.sublist(offset, (offset + count).clamp(0, pool.length));
    }
  }
}

CombinedNewsApiRetriever? _combinedNewsApiRetriever;
CombinedNewsApiRetriever get combinedNewsApiRetriever {
  _combinedNewsApiRetriever ??= CombinedNewsApiRetriever(
    newsApiRetriever,
    RssApiRetriever(httpClient),
  );
  return _combinedNewsApiRetriever!;
}
