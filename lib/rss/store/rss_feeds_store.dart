import 'dart:convert';

import 'package:hackernews/rss/models/rss_feed.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RssFeedsStore {
  late Box<String> _box;
  List<RssFeedInfo> feeds = [];

  static const _feedsKey = 'feeds';

  Future<void> _init() async {
    _box = await Hive.openBox<String>('rssFeeds');
    final raw = _box.get(_feedsKey) ?? '[]';
    feeds = (jsonDecode(raw) as List)
        .map((m) => RssFeedInfo.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  void _persist() =>
      _box.put(_feedsKey, jsonEncode(feeds.map((f) => f.toMap()).toList()));

  void addFeed(RssFeedInfo feed) {
    feeds.add(feed);
    _persist();
  }

  void removeFeed(int index) {
    feeds.removeAt(index);
    _persist();
  }

  static Future<RssFeedsStore> create() async {
    final store = RssFeedsStore();
    await store._init();
    return store;
  }
}

RssFeedsStore? _rssFeedsStore;

RssFeedsStore get rssFeedsStore {
  if (_rssFeedsStore == null) {
    throw Exception('RssFeedsStore not initialized');
  }
  return _rssFeedsStore!;
}

Future<void> initRssFeedsStore() async {
  _rssFeedsStore = await RssFeedsStore.create();
}
