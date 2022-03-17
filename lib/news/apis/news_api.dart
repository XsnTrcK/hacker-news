// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:convert';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:hackernews/services/config.dart' as config;

abstract class NewsApi {
  const NewsApi();

  Future init();
  Future refresh(NewsType newsType);
  Future<List<TitledItem>> getNews(NewsType newsType,
      {int count = 50, int offset = 0});
}

class NewsApiRetriever implements NewsApi {
  final Client _httpClient;
  final Map<NewsType, List<int>> _newsIdsMap = {};
  late Box<String>? _newsBox;

  NewsApiRetriever(this._httpClient);

  @override
  Future init() async {
    _newsBox = await Hive.openBox<String>("news");
  }

  Future<Item> _getNewsItem(int id) async {
    final response = await _httpClient.get(config.getItemUri(id));
    return Item.fromJson(response.body);
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
    var index = offset + 1;
    var endIndex = index + count >= _newsIdsMap[newsType]!.length
        ? _newsIdsMap[newsType]!.length
        : index + count;
    List<TitledItem> newsToReturn = [];
    for (; index < endIndex; index++) {
      final newsId = _newsIdsMap[newsType]![index];
      Item? newsItem;
      if (_newsBox!.containsKey(newsId)) {
        final newsString = _newsBox?.get(newsId);
        if (newsString == null) continue;
        newsItem = Item.fromJson(newsString);
      } else {
        newsItem = await _getNewsItem(newsId);
        _newsBox!.put(newsId, jsonEncode(newsItem.toMap()));
      }
      newsToReturn.add(newsItem as TitledItem);
    }

    return newsToReturn;
  }
}
