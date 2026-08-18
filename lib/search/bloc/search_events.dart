abstract class SearchEvent {
  const SearchEvent();
}

class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);
}

class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}
