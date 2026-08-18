import 'dart:convert';
import 'dart:developer';

import 'package:hackernews/models/item.dart';
import 'package:http/http.dart';

class AlgoliaSearchResult {
  final List<TitledItem> items;
  final int page;
  final int nbPages;

  const AlgoliaSearchResult({
    required this.items,
    required this.page,
    required this.nbPages,
  });

  bool get hasMore => page + 1 < nbPages;
}

class AlgoliaStorySearchApi {
  static const _algoliaBase = 'https://hn.algolia.com/api/v1/search';

  final Client _httpClient;

  const AlgoliaStorySearchApi(this._httpClient);

  TitledItem _mapHit(Map<String, dynamic> hit) {
    final id = int.tryParse('${hit['objectID'] ?? hit['story_id']}') ?? 0;
    final time = hit['created_at_i'] as int? ?? 0;
    final createdBy = hit['author'] as String? ?? '';
    final title = hit['title'] as String? ?? '';
    final score = hit['points'] as int? ?? 0;
    final childrenIds = (hit['children'] as List?)?.cast<int>() ?? [];
    final numberOfChildren = hit['num_comments'] as int? ?? 0;
    final storyText = hit['story_text'] as String?;

    if (storyText != null) {
      return AskItem(
        id,
        time,
        createdBy,
        ItemState(),
        storyText,
        title,
        score,
        childrenIds,
        numberOfChildren,
      );
    }

    return StoryItem(
      id,
      time,
      createdBy,
      ItemState(),
      title,
      score,
      childrenIds,
      numberOfChildren,
      hit['url'] as String? ?? '',
    );
  }

  Future<AlgoliaSearchResult> search(String query, {int page = 0}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const AlgoliaSearchResult(items: [], page: 0, nbPages: 0);
    }
    try {
      final uri = Uri.parse(_algoliaBase).replace(queryParameters: {
        'query': trimmed,
        'tags': 'story',
        'page': '$page',
      });
      final response = await _httpClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final hits = (body['hits'] as List? ?? []).cast<Map<String, dynamic>>();
      return AlgoliaSearchResult(
        items: hits.map(_mapHit).toList(),
        page: (body['page'] as int?) ?? page,
        nbPages: (body['nbPages'] as int?) ?? 0,
      );
    } catch (e) {
      log('Algolia story search failed for "$trimmed": $e');
      rethrow;
    }
  }
}
