import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/store/bookmarks_store.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import '../support/hive_test_support.dart';

StoryItem _story(int id) => StoryItem(
      id,
      0,
      'alice',
      ItemState(),
      'Story $id',
      10,
      const [],
      0,
      'https://example.com/$id',
    );

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = setUpHive();
    await initBookmarksStore();
  });

  tearDown(() => tearDownHive(hiveDir));

  test('getNews reads bookmarked articles without any network request',
      () async {
    bookmarksStore.addBookmark(_story(1));
    bookmarksStore.addBookmark(_story(2));

    final networkSpy = MockClient((request) async {
      fail('SavedArticlesRetriever should not make network requests');
    });

    final retriever = SavedArticlesRetriever(networkSpy);
    final news = await retriever.getNews(NewsType.top);

    expect(news.map((item) => item.id).toSet(), {1, 2});
  });

  test('getNews respects offset/count pagination', () async {
    bookmarksStore.addBookmark(_story(1));
    await Future.delayed(const Duration(milliseconds: 2));
    bookmarksStore.addBookmark(_story(2));

    final retriever = SavedArticlesRetriever(Client());
    final firstPage = await retriever.getNews(NewsType.top, count: 1);
    expect(firstPage.single.id, 2);

    final secondPage =
        await retriever.getNews(NewsType.top, count: 1, offset: 1);
    expect(secondPage.single.id, 1);
  });
}
