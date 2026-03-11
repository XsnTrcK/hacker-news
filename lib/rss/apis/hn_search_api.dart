import 'dart:convert';
import 'dart:developer';

import 'package:hackernews/models/item.dart';
import 'package:hackernews/services/config.dart' as config;
import 'package:http/http.dart';

class HnSearchApi {
  static const _algoliaBase = 'https://hn.algolia.com/api/v1/search';

  static Future<ItemWithKids?> findHnItemForUrl(
      String url, Client client) async {
    try {
      final uri = Uri.parse(_algoliaBase).replace(queryParameters: {
        'query': url,
        'restrictSearchableAttributes': 'url',
      });
      final response = await client.get(uri);
      final hits = (jsonDecode(response.body)['hits'] as List);
      if (hits.isEmpty) return null;

      final hnId = int.tryParse(hits.first['objectID'] as String);
      if (hnId == null) return null;

      final itemResponse = await client.get(config.getItemUri(hnId));
      final item = Item.fromJson(itemResponse.body);
      return item is ItemWithKids ? item : null;
    } catch (e) {
      log('HN Algolia search failed for $url: $e');
      return null;
    }
  }
}
