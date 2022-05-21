// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:convert';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/store/store.dart';
import 'package:http/http.dart';
import 'package:hackernews/services/config.dart' as config;

abstract class NewsApi {
  final Client _httpClient;
  const NewsApi(this._httpClient);

  Future init();
  Future refresh(NewsType newsType);
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0});

  Future<Item> _getNewsItem(int id) async {
    final response = await _httpClient.get(config.getItemUri(id));
    return Item.fromJson(response.body);
  }
}

Client? _client;
Client get httpClient {
  return _client ?? (_client = Client());
}

SavedArticlesRetriever? _savedArticlesRetriever;
Future<SavedArticlesRetriever> getSavedArticlesRetriever() async {
  if (_savedArticlesRetriever != null) return _savedArticlesRetriever!;
  _savedArticlesRetriever = SavedArticlesRetriever(httpClient);
  await _savedArticlesRetriever!.init();
  return _savedArticlesRetriever!;
}

NewsApiRetriever? _newsApiRetriever;
Future<NewsApiRetriever> getNewsApiRetriever({bool deleteBox = false}) async {
  if (_newsApiRetriever != null) return _newsApiRetriever!;
  _newsApiRetriever = NewsApiRetriever(httpClient);
  await _newsApiRetriever!.init(deleteBox: deleteBox);
  return _newsApiRetriever!;
}

class SavedArticlesRetriever extends NewsApi {
  late Store<Item> _store;
  late List<int> _savedNews = [];
  late void Function() _updateSavedNews;

  SavedArticlesRetriever(Client client) : super(client);

  @override
  Future init() async {
    final store = await getNewsStore();
    _updateSavedNews = () => _savedNews = store.savedItems;
    _store = store;
    _updateSavedNews();
  }

  @override
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0}) async {
    if (offset >= _savedNews.length) {
      return [];
    }
    var endIndex = offset + count >= _savedNews.length
        ? _savedNews.length
        : offset + count;
    List<TitledItem> newsToReturn = [];
    for (; offset < endIndex; offset++) {
      final newsId = _savedNews[offset];
      Item? newsItem;
      if (_store.containsKey(newsId)) {
        newsItem = _store.get(newsId);
      } else {
        newsItem = await _getNewsItem(newsId);
        _store.save(newsItem);
      }
      newsToReturn.add(newsItem as TitledItem);
    }

    return newsToReturn;
  }

  @override
  Future refresh(NewsType newsType) async => _updateSavedNews();
}

class NewsApiRetriever extends NewsApi {
  final Map<NewsType, List<int>> _newsIdsMap = {};
  late Store<Item> _newsStore;

  NewsApiRetriever(Client httpClient) : super(httpClient);

  @override
  Future init({bool deleteBox = false}) async {
    // Should this be refactored out?
    _newsStore = await getNewsStore(deleteBox: deleteBox);
  }

  List<int> _convertNewsIds(String newsIdsJson) {
    return (jsonDecode(newsIdsJson) as List<dynamic>).cast<int>();
  }

  Uri _getRetrievalUri(NewsType newsType) {
    switch (newsType) {
      case NewsType.top:
        return config.topStoriesUri;
      case NewsType.newStories:
        return config.newStoriesUri;
      case NewsType.best:
        return config.bestStoriesUri;
      case NewsType.ask:
        return config.askStoriesUri;
      case NewsType.show:
        return config.showStoriesUri;
      case NewsType.job:
        return config.jobStoriesUri;
    }
  }

  @override
  Future refresh(NewsType newsType) async {
    final response = await _httpClient.get(_getRetrievalUri(newsType));
    final newsItems = _convertNewsIds(response.body);
    _newsIdsMap[newsType] = [
      ...{...newsItems..addAll(_newsIdsMap[newsType] ?? [])}
    ];
  }

  @override
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0}) async {
    if (offset >= (_newsIdsMap[newsType]?.length ?? 0)) {
      return [];
    }
    var endIndex = offset + count >= _newsIdsMap[newsType]!.length
        ? _newsIdsMap[newsType]!.length
        : offset + count;
    List<TitledItem> newsToReturn = [];
    for (; offset < endIndex; offset++) {
      final newsId = _newsIdsMap[newsType]![offset];
      Item? newsItem;
      if (_newsStore.containsKey(newsId)) {
        newsItem = _newsStore.get(newsId);
      } else {
        newsItem = await _getNewsItem(newsId);
        _newsStore.save(newsItem);
      }
      newsToReturn.add(newsItem as TitledItem);
    }

    return newsToReturn;
  }
}
