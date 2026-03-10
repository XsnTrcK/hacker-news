import 'package:hackernews/models/item.dart' show TitledItem;
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/apis/rss_api.dart';

class CombinedNewsApiRetriever extends NewsApi {
  final NewsApiRetriever _hnApi;
  final RssApiRetriever _rssApi;
  List<TitledItem> _cachedRssItems = [];
  List<TitledItem> _hnItemsFetched = [];
  bool _hnExhausted = false;

  CombinedNewsApiRetriever(this._hnApi, this._rssApi) : super(httpClient);

  @override
  Future<void> refresh(NewsType newsType) async {
    _hnItemsFetched = [];
    _hnExhausted = false;
    await Future.wait([
      _hnApi.refresh(newsType),
      _rssApi.fetchAllFeeds().then((items) => _cachedRssItems = List<TitledItem>.from(items)),
    ]);
  }

  @override
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0}) async {
    if (offset == 0) {
      _hnItemsFetched = [];
      _hnExhausted = false;
    }

    // Fetch more HN items until the combined pool is large enough to serve
    // the requested page, or the HN feed is exhausted.
    while (!_hnExhausted) {
      final poolSize = _cachedRssItems.length + _hnItemsFetched.length;
      if (poolSize >= offset + count) break;

      final hnItems = await _hnApi.getNews(
        newsType,
        count: count,
        offset: _hnItemsFetched.length,
      );
      if (hnItems.isEmpty) {
        _hnExhausted = true;
        break;
      }
      _hnItemsFetched.addAll(hnItems);
    }

    final pool = <TitledItem>[..._cachedRssItems, ..._hnItemsFetched];
    pool.sort((a, b) => b.time.compareTo(a.time));

    if (offset >= pool.length) return [];
    return pool.sublist(offset, (offset + count).clamp(0, pool.length));
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
