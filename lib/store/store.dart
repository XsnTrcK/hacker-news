import 'dart:convert';

import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class Store<T> {
  final Map<int, T> _store = {};

  void save(T item);
  T get<TKey>(TKey key);
  bool containsKey<TKey>(TKey key);
}

abstract class ItemUpdater<T> {
  final String _savedItemsKey = "savedItems";
  late List<int> savedItems = [];

  T saveToReadLater(T item);
  T markHasBeenRead(T item);
  T displayReaderMode(T item);
}

NewsStore? _newsStore;
Future<NewsStore> getNewsStore() async {
  if (_newsStore != null) return _newsStore!;
  _newsStore = NewsStore();
  await _newsStore!.init();
  return _newsStore!;
}

class NewsStore extends Store<Item> with ItemUpdater<Item> {
  late Box<String> _newsBox;

  Future init() async {
    _newsBox = await Hive.openBox<String>("news");
    savedItems =
        (jsonDecode(_newsBox.get(_savedItemsKey) ?? "[]") as List).cast<int>();
  }

  @override
  bool containsKey<TKey>(TKey key) {
    if (!_store.containsKey(key)) {
      if (_newsBox.containsKey(key)) {
        final itemString = _newsBox.get(key);
        final item = Item.fromJson(itemString!);
        _store[item.id] = item;
      }
    }
    return _store.containsKey(key);
  }

  @override
  Item get<TKey>(TKey key) => _store[key]!;

  @override
  void save(Item item) {
    _store[item.id] = item;
    _newsBox.put(item.id, jsonEncode(item.toMap()));
  }

  @override
  Item markHasBeenRead(Item item) {
    item.state.hasBeenRead = true;
    save(item);
    return item;
  }

  @override
  Item saveToReadLater(Item item) {
    item.state.savedForReadLater = !item.state.savedForReadLater;
    save(item);
    if (item.state.savedForReadLater) {
      savedItems.insert(0, item.id);
    } else {
      savedItems.remove(item.id);
    }
    _newsBox.put(_savedItemsKey, jsonEncode(savedItems));
    return item;
  }

  @override
  Item displayReaderMode(Item item) {
    item.state.displayReaderMode = !item.state.displayReaderMode;
    save(item);
    return item;
  }
}
