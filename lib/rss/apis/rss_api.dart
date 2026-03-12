import 'dart:developer';

import 'package:dart_rss/dart_rss.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/rss/models/rss_feed.dart';
import 'package:hackernews/rss/models/rss_story_item.dart';
import 'package:hackernews/rss/store/rss_feeds_store.dart';
import 'package:http/http.dart';

class RssApiRetriever {
  final Client _httpClient;

  RssApiRetriever(this._httpClient);

  Future<List<RssStoryItem>> fetchAllFeeds() async {
    if (rssFeedsStore.feeds.isEmpty) return [];
    final results = await Future.wait(
      rssFeedsStore.feeds.map(_fetchFeed),
    );
    return results.expand((items) => items).toList();
  }

  Future<List<RssStoryItem>> fetchFeed(RssFeedInfo feed) => _fetchFeed(feed);

  Future<List<RssStoryItem>> _fetchFeed(RssFeedInfo feed) async {
    try {
      final response = await _httpClient.get(Uri.parse(feed.url));
      final webFeed = WebFeed.fromXmlString(response.body);
      return _convertItems(webFeed.items, feed);
    } catch (e) {
      log('Failed to fetch RSS feed ${feed.url}: $e');
      return [];
    }
  }

  List<RssStoryItem> _convertItems(
      List<WebFeedItem> items, RssFeedInfo feed) {
    final result = <RssStoryItem>[];
    for (final item in items) {
      final url = item.links.whereType<String>().firstOrNull;
      final title = item.title;
      if (url == null || url.isEmpty || title.isEmpty) continue;

      final time = item.updated != null
          ? item.updated!.millisecondsSinceEpoch ~/ 1000
          : 0;

      result.add(RssStoryItem(
        id: RssStoryItem.stableHash(url),
        time: time,
        createdBy: feed.name,
        state: ItemState(),
        title: title,
        url: url,
        feedName: feed.name,
      ));
    }
    return result;
  }
}
