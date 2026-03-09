import 'package:hackernews/models/item.dart' show TitledItem;
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/apis/rss_api.dart';
import 'package:hackernews/rss/models/rss_story_item.dart';

class CombinedNewsApiRetriever extends NewsApi {
  final NewsApiRetriever _hnApi;
  final RssApiRetriever _rssApi;
  List<RssStoryItem> _cachedRssItems = [];

  CombinedNewsApiRetriever(this._hnApi, this._rssApi) : super(httpClient);

  @override
  Future<void> refresh(NewsType newsType) async {
    await Future.wait([
      _hnApi.refresh(newsType),
      _rssApi.fetchAllFeeds().then((items) => _cachedRssItems = items),
    ]);
  }

  @override
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0}) async {
    final hnItems =
        await _hnApi.getNews(newsType, count: count, offset: offset);
    if (offset == 0) {
      final combined = <TitledItem>[..._cachedRssItems, ...hnItems];
      combined.sort((a, b) => b.time.compareTo(a.time));
      return combined;
    }
    return hnItems;
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
