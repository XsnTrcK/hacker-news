import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/search/apis/algolia_story_search_api.dart';
import 'package:hackernews/search/bloc/search_bloc.dart';
import 'package:hackernews/search/bloc/search_events.dart';
import 'package:hackernews/search/bloc/search_state.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

Response _hitsResponse(String title, {int page = 0, int nbPages = 1}) {
  return Response(
    jsonEncode({
      'hits': [
        {
          'objectID': '1',
          'created_at_i': 1000,
          'author': 'alice',
          'title': title,
          'points': 1,
          'num_comments': 0,
          'url': 'https://example.com',
        },
      ],
      'page': page,
      'nbPages': nbPages,
    }),
    200,
  );
}

StoryItem _existingResult() => StoryItem(
      1,
      0,
      'alice',
      ItemState(),
      'Existing result',
      1,
      const [],
      0,
      'https://example.com/1',
    );

void main() {
  group('SearchQueryChanged', () {
    blocTest<SearchBloc, SearchState>(
      'emits loading then success with mapped results',
      build: () => SearchBloc(AlgoliaStorySearchApi(
        MockClient((request) async => _hitsResponse('A story')),
      )),
      act: (bloc) => bloc.add(const SearchQueryChanged('flutter')),
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'flutter'),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.success)
            .having((s) => s.query, 'query', 'flutter')
            .having((s) => s.results, 'results', hasLength(1)),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'blank query resets to the initial state without a request',
      build: () => SearchBloc(AlgoliaStorySearchApi(
        MockClient((request) async => fail('should not be called')),
      )),
      seed: () =>
          const SearchState(status: SearchStatus.success, query: 'flutter'),
      act: (bloc) => bloc.add(const SearchQueryChanged('   ')),
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'a failed request emits a failure state',
      build: () => SearchBloc(AlgoliaStorySearchApi(
        MockClient((request) async => Response('error', 500)),
      )),
      act: (bloc) => bloc.add(const SearchQueryChanged('flutter')),
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'flutter'),
        const SearchState(status: SearchStatus.failure, query: 'flutter'),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'a newer query wins over a slower in-flight older query',
      build: () => SearchBloc(AlgoliaStorySearchApi(
        MockClient((request) async {
          final query = request.url.queryParameters['query'];
          if (query == 'slow') {
            await Future.delayed(const Duration(milliseconds: 100));
            return _hitsResponse('slow result');
          }
          return _hitsResponse('fast result');
        }),
      )),
      act: (bloc) async {
        bloc.add(const SearchQueryChanged('slow'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(const SearchQueryChanged('fast'));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.status, SearchStatus.success);
        expect(bloc.state.query, 'fast');
        expect(bloc.state.results.single.title, 'fast result');
      },
    );
  });

  group('SearchNextPageRequested', () {
    blocTest<SearchBloc, SearchState>(
      'appends the next page of results to the existing list',
      build: () => SearchBloc(AlgoliaStorySearchApi(
        MockClient((request) async {
          final page = int.parse(request.url.queryParameters['page']!);
          return _hitsResponse('page $page', page: page, nbPages: 2);
        }),
      )),
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'flutter',
        results: [_existingResult()],
      ),
      act: (bloc) => bloc.add(const SearchNextPageRequested()),
      verify: (bloc) {
        expect(bloc.state.results, hasLength(2));
        expect(bloc.state.page, 1);
        expect(bloc.state.hasReachedMax, isTrue);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'does nothing when already at the last page',
      build: () => SearchBloc(AlgoliaStorySearchApi(
        MockClient((request) async => fail('should not be called')),
      )),
      seed: () => const SearchState(
        status: SearchStatus.success,
        query: 'flutter',
        hasReachedMax: true,
      ),
      act: (bloc) => bloc.add(const SearchNextPageRequested()),
      expect: () => [],
    );
  });
}
