import 'dart:convert';

import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BookmarksStore {
  late Box<String> _box;

  Future<void> _init({bool deleteBox = false}) async {
    _box = await Hive.openBox<String>('bookmarks');
    if (deleteBox) {
      await _box.deleteFromDisk();
      _box = await Hive.openBox<String>('bookmarks');
    }
  }

  void addBookmark(Item item) {
    _box.put(
      item.id,
      jsonEncode({
        "bookmarkedAt": DateTime.now().millisecondsSinceEpoch,
        "item": item.toMap(),
      }),
    );
  }

  void removeBookmark(int id) => _box.delete(id);

  bool containsBookmark(int id) => _box.containsKey(id);

  /// All bookmarked items, most-recently-bookmarked first.
  List<Item> orderedBookmarks() {
    final entries = _box.values.map((raw) {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final bookmarkedAt = decoded["bookmarkedAt"] as int;
      final item = Item.fromMap(decoded["item"] as Map<String, dynamic>);
      return (bookmarkedAt, item);
    }).toList();
    entries.sort((a, b) => b.$1.compareTo(a.$1));
    return entries.map((e) => e.$2).toList();
  }

  static Future<BookmarksStore> create(bool deleteBox) async {
    final store = BookmarksStore();
    await store._init(deleteBox: deleteBox);
    return store;
  }
}

BookmarksStore? _bookmarksStore;

BookmarksStore get bookmarksStore {
  if (_bookmarksStore == null) {
    throw Exception('BookmarksStore not initialized');
  }
  return _bookmarksStore!;
}

Future<void> initBookmarksStore({bool deleteBox = false}) async {
  _bookmarksStore = await BookmarksStore.create(deleteBox);
}
