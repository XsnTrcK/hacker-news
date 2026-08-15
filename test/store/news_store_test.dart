import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/store/bookmarks_store.dart';
import 'package:hackernews/store/store.dart';

import '../support/hive_test_support.dart';

StoryItem _story(int id, {ItemState? state}) => StoryItem(
      id,
      0,
      'alice',
      state ?? ItemState(),
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
    // NewsStore.saveToReadLater writes through to the bookmarks store too.
    await initBookmarksStore();
  });

  tearDown(() => tearDownHive(hiveDir));

  test('an article never toggled is not persisted', () async {
    final store = await NewsStore.create(false);
    store.save(_story(1));
    expect(store.leanRecord(1), isNull);
  });

  test('toggling reader mode persists a lean record with bookmarked null',
      () async {
    final store = await NewsStore.create(false);
    final item = _story(2);
    store.displayReaderMode(item);

    final record = store.leanRecord(2);
    expect(record, isNotNull);
    expect(record!.displayReaderMode, true);
    expect(record.bookmarked, isNull);
  });

  test('bookmarking persists a lean record with displayReaderMode null',
      () async {
    final store = await NewsStore.create(false);
    final item = _story(3);
    store.saveToReadLater(item);

    final record = store.leanRecord(3);
    expect(record, isNotNull);
    expect(record!.bookmarked, true);
    expect(record.displayReaderMode, isNull);
  });

  test('containsKey/get are in-memory only for the current session',
      () async {
    final store = await NewsStore.create(false);
    expect(store.containsKey(4), isFalse);

    final item = _story(4);
    store.save(item);
    expect(store.containsKey(4), isTrue);
    expect(store.get(4), same(item));
  });

  test('applyStoredState reapplies a persisted toggle onto a freshly '
      'fetched item', () async {
    final store = await NewsStore.create(false);
    store.displayReaderMode(_story(5));

    final freshlyFetched = _story(5);
    expect(freshlyFetched.state.displayReaderMode, isNull);

    store.applyStoredState(freshlyFetched);
    expect(freshlyFetched.state.displayReaderMode, true);
  });
}
