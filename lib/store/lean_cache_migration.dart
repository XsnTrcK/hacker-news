import 'dart:convert';

import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _migrationCompleteKey = 'leanHiveCacheMigrationComplete';
const _legacySavedItemsKey = 'savedItems';

/// One-time migration from the pre-lean-cache Hive shape (full item content
/// cached forever in "news", an ordered id list under `_legacySavedItemsKey`
/// mixed into the same box, and full comment bodies cached in "comments")
/// to the lean shape: bookmarks moved to a dedicated "bookmarks" box,
/// reader-mode toggles preserved as lean records, and "comments" wiped.
///
/// Runs at most once per install, gated by a flag in the "settings" box.
/// The flag is written last so an interrupted run safely re-executes: each
/// step is either idempotent (re-writing the same bookmark/lean record) or
/// naturally skipped (a key already rewritten to the lean shape fails to
/// decode as a full `Item` and is left alone).
Future<void> runLeanHiveCacheMigration() async {
  final settingsBox = await Hive.openBox<String>('settings');
  if (settingsBox.get(_migrationCompleteKey) == 'true') {
    return;
  }

  final newsBox = await Hive.openBox<String>('news');
  final bookmarksBox = await Hive.openBox<String>('bookmarks');

  final legacySavedIds =
      (jsonDecode(newsBox.get(_legacySavedItemsKey) ?? '[]') as List)
          .cast<int>();
  final legacySavedIdsSet = legacySavedIds.toSet();

  final now = DateTime.now().millisecondsSinceEpoch;
  for (var index = 0; index < legacySavedIds.length; index++) {
    final id = legacySavedIds[index];
    final item = _decodeFullItem(newsBox.get(id));
    if (item == null) continue;
    await bookmarksBox.put(
      id,
      jsonEncode({
        "bookmarkedAt": now - index,
        "item": item.toMap(),
      }),
    );
  }

  for (final key in newsBox.keys.toList()) {
    if (key == _legacySavedItemsKey) continue;
    final item = _decodeFullItem(newsBox.get(key));
    if (item == null) continue;

    final wasBookmarked = legacySavedIdsSet.contains(item.id);
    final touched = item.state.displayReaderMode != null || wasBookmarked;
    if (touched) {
      await newsBox.put(
        item.id,
        LeanItemRecord(
          id: item.id,
          displayReaderMode: item.state.displayReaderMode,
          bookmarked: wasBookmarked ? true : null,
        ).toJson(),
      );
    } else {
      await newsBox.delete(item.id);
    }
  }

  await newsBox.delete(_legacySavedItemsKey);
  await Hive.deleteBoxFromDisk('comments');

  await settingsBox.put(_migrationCompleteKey, 'true');
}

Item? _decodeFullItem(String? raw) {
  if (raw == null) return null;
  try {
    return Item.fromJson(raw);
  } catch (_) {
    // Already rewritten to the lean shape (or otherwise unparseable as a
    // full item) by an earlier, interrupted run of this migration.
    return null;
  }
}
