import 'dart:convert';

import 'package:hackernews/models/item.dart';
import 'package:hackernews/store/bookmarks_store.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class Store<T> {
  final Map<int, T> _store = {};

  void save(T item);
  T get<TKey>(TKey key);
  bool containsKey<TKey>(TKey key);
}

abstract mixin class ItemUpdater<T> {
  T saveToReadLater(T item);
  T displayReaderMode(T item);
}

NewsStore? _newsStore;
NewsStore get newsStore {
  if (_newsStore == null) {
    throw Exception("Should only retrieve when initialized");
  }
  return _newsStore!;
}

Future initNewsStore({bool deleteBox = false}) async {
  _newsStore = await NewsStore.create(deleteBox);
}

class NewsStore extends Store<Item> with ItemUpdater<Item> {
  late Box<String> _newsBox;

  Future _init({bool deleteBox = false}) async {
    _newsBox = await Hive.openBox<String>("news");

    if (deleteBox) {
      _newsBox.deleteFromDisk();
    }
  }

  // The "news" box only ever holds lean records now, so containsKey/get are
  // pure in-memory lookups scoped to the current session — they cannot
  // reconstruct a full Item from disk (title/url/score are never persisted).
  @override
  bool containsKey<TKey>(TKey key) => _store.containsKey(key);

  @override
  Item get<TKey>(TKey key) => _store[key]!;

  LeanItemRecord? leanRecord(int id) {
    final raw = _newsBox.get(id);
    return raw == null ? null : LeanItemRecord.fromJson(raw);
  }

  /// Re-applies a previously persisted reader-mode/bookmark toggle onto a
  /// freshly network-fetched item, since full content is never cached.
  void applyStoredState(Item item) {
    final record = leanRecord(item.id);
    if (record == null) return;
    item.state.displayReaderMode = record.displayReaderMode;
    item.state.savedForReadLater = record.bookmarked;
  }

  @override
  void save(Item item) {
    _store[item.id] = item;
    final touched = item.state.displayReaderMode != null ||
        item.state.savedForReadLater != null;
    if (touched) {
      _newsBox.put(item.id, jsonEncode(item.toLeanMap()));
    }
  }

  @override
  Item saveToReadLater(Item item) {
    item.state.savedForReadLater = !(item.state.savedForReadLater ?? false);
    save(item);
    if (item.state.savedForReadLater == true) {
      bookmarksStore.addBookmark(item);
    } else {
      bookmarksStore.removeBookmark(item.id);
    }
    return item;
  }

  @override
  Item displayReaderMode(Item item) {
    item.state.displayReaderMode = !(item.state.displayReaderMode ?? false);
    save(item);
    return item;
  }

  static Future<NewsStore> create(bool deleteBox) async {
    final newsStore = NewsStore();
    await newsStore._init(deleteBox: deleteBox);
    return newsStore;
  }
}
