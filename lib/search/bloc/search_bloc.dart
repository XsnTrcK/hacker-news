import 'dart:developer';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/search/apis/algolia_story_search_api.dart';
import 'package:hackernews/search/bloc/search_events.dart';
import 'package:hackernews/search/bloc/search_state.dart';

class SearchBloc extends ThrottledBloc<SearchEvent, SearchState> {
  final AlgoliaStorySearchApi _searchApi;

  SearchBloc(this._searchApi) : super(const SearchState()) {
    // Restartable (not throttleDroppable): a query typed while the previous
    // search is still in flight must win, not get dropped in favor of the
    // stale in-flight request's result.
    on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());
    on<SearchNextPageRequested>(_onNextPageRequested,
        transformer: throttleDroppable());
  }

  Future<void> _onQueryChanged(
      SearchQueryChanged event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }
    emit(SearchState(status: SearchStatus.loading, query: query));
    try {
      final result = await _searchApi.search(query, page: 0);
      emit(SearchState(
        status:
            result.items.isEmpty ? SearchStatus.empty : SearchStatus.success,
        query: query,
        results: result.items,
        page: result.page,
        hasReachedMax: !result.hasMore,
      ));
    } catch (error) {
      log('Search failed for "$query": $error');
      emit(SearchState(status: SearchStatus.failure, query: query));
    }
  }

  Future<void> _onNextPageRequested(
      SearchNextPageRequested event, Emitter<SearchState> emit) async {
    if (state.status != SearchStatus.success || state.hasReachedMax) return;
    try {
      final result =
          await _searchApi.search(state.query, page: state.page + 1);
      emit(state.copyWith(
        results: List.of(state.results)..addAll(result.items),
        page: result.page,
        hasReachedMax: !result.hasMore,
      ));
    } catch (error) {
      log('Search pagination failed for "${state.query}": $error');
    }
  }
}
