import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/search/apis/algolia_story_search_api.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  group('search', () {
    test('empty query returns an empty result without making a request',
        () async {
      final api = AlgoliaStorySearchApi(
        MockClient((request) async => fail('should not be called')),
      );

      final result = await api.search('   ');

      expect(result.items, isEmpty);
      expect(result.page, 0);
      expect(result.nbPages, 0);
    });

    test('non-200 response throws instead of decoding the body', () async {
      final api = AlgoliaStorySearchApi(
        MockClient((request) async => Response('not json', 500)),
      );

      expect(() => api.search('flutter'), throwsException);
    });

    test('maps a regular hit to a StoryItem', () async {
      final api = AlgoliaStorySearchApi(
        MockClient((request) async => Response(
              jsonEncode({
                'hits': [
                  {
                    'objectID': '42',
                    'created_at_i': 1000,
                    'author': 'alice',
                    'title': 'A story',
                    'points': 10,
                    'num_comments': 3,
                    'url': 'https://example.com',
                  },
                ],
                'page': 0,
                'nbPages': 5,
              }),
              200,
            )),
      );

      final result = await api.search('flutter');

      expect(result.items, hasLength(1));
      final item = result.items.single;
      expect(item, isA<StoryItem>());
      expect(item.id, 42);
      expect(item.title, 'A story');
      expect((item as StoryItem).url, 'https://example.com');
    });

    test('maps a self-text hit to an AskItem', () async {
      final api = AlgoliaStorySearchApi(
        MockClient((request) async => Response(
              jsonEncode({
                'hits': [
                  {
                    'objectID': '7',
                    'created_at_i': 1000,
                    'author': 'bob',
                    'title': 'Ask HN: something',
                    'points': 4,
                    'num_comments': 1,
                    'story_text': 'body text',
                  },
                ],
                'page': 0,
                'nbPages': 1,
              }),
              200,
            )),
      );

      final result = await api.search('ask hn');

      expect(result.items.single, isA<AskItem>());
      expect((result.items.single as AskItem).text, 'body text');
    });

    test('hasMore reflects page/nbPages from the response', () async {
      final api = AlgoliaStorySearchApi(
        MockClient((request) async => Response(
              jsonEncode({'hits': [], 'page': 0, 'nbPages': 3}),
              200,
            )),
      );

      final result = await api.search('flutter');

      expect(result.page, 0);
      expect(result.nbPages, 3);
      expect(result.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () async {
      final api = AlgoliaStorySearchApi(
        MockClient((request) async => Response(
              jsonEncode({'hits': [], 'page': 2, 'nbPages': 3}),
              200,
            )),
      );

      final result = await api.search('flutter', page: 2);

      expect(result.hasMore, isFalse);
    });
  });
}
