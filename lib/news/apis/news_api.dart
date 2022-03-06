// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:convert';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:hackernews/services/config.dart' as config;

abstract class NewsApi {
  const NewsApi();

  Future refresh();

  Future<List<TitledItem>> getNews({int count = 50, int offset = 0});
}

class NewsApiRetriever implements NewsApi {
  final Client _httpClient;
  final CommentsFetcher _commentsFetcher;
  late List<int> _newsIds = const [];
  Box<String>? _newsBox;

  NewsApiRetriever(this._httpClient, this._commentsFetcher);

  Future<Item> _getNewsItem(int id) async {
    final response = await _httpClient.get(config.getItemUri(id));
    return Item.fromJson(response.body);
  }

  Future _retrieveNews() async {
    final response = await _httpClient.get(config.topStoriesUri);
    final newsItems = _convertNewsIds(response.body);
    _newsIds = newsItems..addAll(_newsIds);
  }

  List<int> _convertNewsIds(String newsIdsJson) {
    return (jsonDecode(newsIdsJson) as List<dynamic>).cast<int>();
  }

  @override
  Future refresh() => _retrieveNews();

  @override
  Future<List<TitledItem>> getNews({int count = 50, int offset = 0}) async {
    _newsBox ??= await Hive.openBox<String>("news");
    if (offset >= _newsIds.length) {
      return [];
    }
    var index = offset + 1;
    var endIndex =
        index + count >= _newsIds.length ? _newsIds.length : index + count;
    List<TitledItem> newsToReturn = [];
    for (; index < endIndex; index++) {
      final newsId = _newsIds[index];
      Item? newsItem;
      if (_newsBox!.containsKey(newsId)) {
        final newsString = _newsBox?.get(newsId);
        if (newsString == null) continue;
        newsItem = Item.fromJson(newsString);
      } else {
        newsItem = await _getNewsItem(newsId);
        if (newsItem is ItemWithKids) {
          _commentsFetcher.fetchComments(newsItem);
        }
        _newsBox!.put(newsId, jsonEncode(newsItem.toMap()));
      }
      newsToReturn.add(newsItem as TitledItem);
    }

    return newsToReturn;
  }
}
