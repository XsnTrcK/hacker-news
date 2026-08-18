import 'package:equatable/equatable.dart';
import 'package:hackernews/models/item.dart';

enum SearchStatus { initial, loading, success, empty, failure }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final List<TitledItem> results;
  final int page;
  final bool hasReachedMax;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const <TitledItem>[],
    this.page = 0,
    this.hasReachedMax = false,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<TitledItem>? results,
    int? page,
    bool? hasReachedMax,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [status, query, results, page, hasReachedMax];
}
