import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/store/lean_cache_migration.dart';
import 'package:hive/hive.dart';

import '../support/hive_test_support.dart';

// Hand-built pre-migration wire shape (including the since-removed
// `hasBeenRead` field) rather than `Item.toMap()`, so this genuinely
// exercises what an old app version actually wrote to disk.
String _legacyStoryJson({
  required int id,
  bool? displayReaderMode,
  bool savedForReadLater = false,
}) {
  return jsonEncode({
    "id": id,
    "time": 0,
    "by": "alice",
    "state": {
      "isExpanded": true,
      "savedForReadLater": savedForReadLater,
      "hasBeenRead": false,
      "displayReaderMode": displayReaderMode,
    },
    "title": "Story $id",
    "score": 10,
    "kids": <int>[],
    "descendants": 0,
    "url": "https://example.com/$id",
    "type": "story",
  });
}

void main() {
  late Directory hiveDir;

  setUp(() => hiveDir = setUpHive());
  tearDown(() => tearDownHive(hiveDir));

  test('migrates bookmarks, reader-mode toggles, and wipes comments',
      () async {
    final newsBox = await Hive.openBox<String>('news');
    // Bookmarked, most-recent first (mirrors the old insert(0, ...) order).
    await newsBox.put('savedItems', jsonEncode([2, 1]));
    await newsBox.put(1, _legacyStoryJson(id: 1, savedForReadLater: true));
    await newsBox.put(
      2,
      _legacyStoryJson(id: 2, savedForReadLater: true, displayReaderMode: true),
    );
    // Reader-mode toggled but never bookmarked.
    await newsBox.put(3, _legacyStoryJson(id: 3, displayReaderMode: true));
    // Never touched — should not survive migration.
    await newsBox.put(4, _legacyStoryJson(id: 4));

    final commentsBox = await Hive.openBox<String>('comments');
    await commentsBox.put(500, jsonEncode({"id": 500, "text": "old cache"}));

    await runLeanHiveCacheMigration();

    final bookmarksBox = Hive.box<String>('bookmarks');
    final bookmark1 = jsonDecode(bookmarksBox.get(1)!) as Map<String, dynamic>;
    final bookmark2 = jsonDecode(bookmarksBox.get(2)!) as Map<String, dynamic>;
    expect(bookmark1["item"]["id"], 1);
    expect(bookmark2["item"]["id"], 2);
    // Order preserved: 2 was bookmarked most recently.
    expect(bookmark2["bookmarkedAt"] as int,
        greaterThan(bookmark1["bookmarkedAt"] as int));

    expect(newsBox.get('savedItems'), isNull);

    final record2 = LeanItemRecord.fromJson(newsBox.get(2)!);
    expect(record2.bookmarked, true);
    expect(record2.displayReaderMode, true);

    final record3 = LeanItemRecord.fromJson(newsBox.get(3)!);
    expect(record3.displayReaderMode, true);
    expect(record3.bookmarked, isNull);

    expect(newsBox.get(4), isNull);

    expect(await Hive.boxExists('comments'), isFalse);

    final settingsBox = Hive.box<String>('settings');
    expect(settingsBox.get('leanHiveCacheMigrationComplete'), 'true');
  });

  test('migration does not re-run on a second launch', () async {
    final newsBox = await Hive.openBox<String>('news');
    await newsBox.put(1, _legacyStoryJson(id: 1, displayReaderMode: true));

    await runLeanHiveCacheMigration();
    // Mutate post-migration state in a way a second run would visibly undo
    // if it incorrectly re-executed.
    await newsBox.delete(1);

    await runLeanHiveCacheMigration();

    expect(newsBox.get(1), isNull);
  });

  test('is idempotent if interrupted and re-triggered', () async {
    final newsBox = await Hive.openBox<String>('news');
    await newsBox.put('savedItems', jsonEncode([1]));
    await newsBox.put(1, _legacyStoryJson(id: 1, savedForReadLater: true));

    await runLeanHiveCacheMigration();

    // Simulate an interruption that left the flag unset despite the box
    // mutations having already completed once.
    final settingsBox = Hive.box<String>('settings');
    await settingsBox.delete('leanHiveCacheMigrationComplete');

    await runLeanHiveCacheMigration();

    final bookmarksBox = Hive.box<String>('bookmarks');
    expect(bookmarksBox.keys.length, 1);
    final record = LeanItemRecord.fromJson(newsBox.get(1)!);
    expect(record.bookmarked, true);
  });
}
