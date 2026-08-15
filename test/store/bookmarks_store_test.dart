import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/store/bookmarks_store.dart';

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

  setUp(() => hiveDir = setUpHive());
  tearDown(() => tearDownHive(hiveDir));

  test('addBookmark writes a full-content record', () async {
    final store = await BookmarksStore.create(false);
    store.addBookmark(_story(1));

    expect(store.containsBookmark(1), isTrue);
    final bookmarks = store.orderedBookmarks();
    expect(bookmarks.single.id, 1);
    expect((bookmarks.single as StoryItem).title, 'Story 1');
  });

  test('removeBookmark deletes the entry', () async {
    final store = await BookmarksStore.create(false);
    store.addBookmark(_story(1));
    store.removeBookmark(1);

    expect(store.containsBookmark(1), isFalse);
    expect(store.orderedBookmarks(), isEmpty);
  });

  test('orderedBookmarks sorts most-recently-bookmarked first', () async {
    final store = await BookmarksStore.create(false);
    store.addBookmark(_story(1));
    // Distinct millisecond timestamps so ordering is deterministic.
    await Future.delayed(const Duration(milliseconds: 2));
    store.addBookmark(_story(2));

    final ids = store.orderedBookmarks().map((item) => item.id).toList();
    expect(ids, [2, 1]);
  });
}
