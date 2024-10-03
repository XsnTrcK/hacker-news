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

  Future refresh(NewsType newsType);
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0});

  Future<Item> getNewsItem(int id) async {
    final response = await _httpClient.get(config.getItemUri(id));
    return Item.fromJson(response.body);
  }
}

Client? _client;
Client get httpClient {
  return _client ?? (_client = Client());
}

class SavedArticlesRetriever extends NewsApi {
  late List<int> _savedNews = [];

  SavedArticlesRetriever(Client client) : super(client) {
    _updateSavedNews();
  }

  void _updateSavedNews() {
    _savedNews = newsStore.savedItems;
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
      if (newsStore.containsKey(newsId)) {
        newsItem = newsStore.get(newsId);
      } else {
        newsItem = await getNewsItem(newsId);
        newsStore.save(newsItem);
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

  NewsApiRetriever(Client httpClient) : super(httpClient);

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
      if (newsStore.containsKey(newsId)) {
        newsItem = newsStore.get(newsId);
      } else {
        newsItem = await getNewsItem(newsId);
        newsStore.save(newsItem);
      }
      newsToReturn.add(newsItem as TitledItem);
    }

    return newsToReturn;
  }

  static Future<NewsApiRetriever> create(bool deleteBox) async {
    final newsApiRetriever = NewsApiRetriever(httpClient);
    return newsApiRetriever;
  }
}

SavedArticlesRetriever? _savedArticlesRetriever;
SavedArticlesRetriever get savedArticlesRetriever {
  _savedArticlesRetriever ??= SavedArticlesRetriever(httpClient);
  return _savedArticlesRetriever!;
}

NewsApiRetriever? _newsApiRetriever;
NewsApiRetriever get newsApiRetriever {
  _newsApiRetriever ??= NewsApiRetriever(httpClient);
  return _newsApiRetriever!;
}
