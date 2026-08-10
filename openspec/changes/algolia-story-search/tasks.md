## 1. API client

- [ ] 1.1 Create `lib/search/apis/algolia_story_search_api.dart` with a `search(String query, {int page})` method calling `GET https://hn.algolia.com/api/v1/search?query=<query>&tags=story&page=<page>`
- [ ] 1.2 Map each hit to `StoryItem` (default case) or `AskItem` (when `story_text` is present), per the field mapping in design.md
- [ ] 1.3 Wrap the HTTP call in try/catch, following `HnSearchApi.findHnItemForUrl`'s error-handling pattern; surface failures as a thrown/returned error the bloc can turn into a failure state
- [ ] 1.4 Handle empty query text (no request, or immediate empty result) and empty `hits` array

## 2. Search bloc

- [ ] 2.1 Create `lib/search/bloc/search_events.dart` with `SearchQueryChanged(query)` and `SearchNextPageRequested` events
- [ ] 2.2 Create `lib/search/bloc/search_state.dart` with status (initial/loading/success/empty/failure), current query, accumulated results, current page, and hasReachedMax flag
- [ ] 2.3 Create `lib/search/bloc/search_bloc.dart` extending `ThrottledBloc`, using `throttleDroppable` on the event transformer consistent with `NewsBloc`
- [ ] 2.4 On `SearchQueryChanged`, reset pagination and fetch page 0; on `SearchNextPageRequested`, fetch the next page and append results

## 3. Search UI

- [ ] 3.1 Create `lib/search/views/search_page.dart`: a text field bound to a debounced (300-400ms) dispatch of `SearchQueryChanged`, plus a `ListView` of results reusing `ImageListItem`
- [ ] 3.2 Wire scroll-to-bottom detection (mirror `News._onScroll`/`_isBottom` in `lib/news/views/news.dart`) to dispatch `SearchNextPageRequested`
- [ ] 3.3 Tapping a result navigates via `CupertinoPageRoute` to `ViewArticles` with the search results list and tapped index, matching `News`'s navigation pattern
- [ ] 3.4 Render empty-results and error states distinctly (no results vs. request failed)

## 4. Entry point

- [ ] 4.1 Track the current `PageView` page in `_HackerNewserNavigationState` (e.g. `onPageChanged` or a `PageController` listener) so it's known whether the news page (index 1) or the menu page (index 0) is active
- [ ] 4.2 Add a `FloatingActionButton` via `Scaffold.floatingActionButton` in `HackerNewserNavigation.build`, shown only when the news page is active AND `_feedMode` is `FeedMode.all` or `FeedMode.hn` (`null` otherwise)
- [ ] 4.3 Tapping it pushes `SearchPage` wrapped in `BlocProvider(create: (_) => SearchBloc(...))`, following the `CupertinoPageRoute` + `ColorfulSafeArea` pattern from `Menu._handleClick`

## 5. Verification

- [ ] 5.1 Manually verify: search for a known story title, confirm result renders and opens with working comments
- [ ] 5.2 Manually verify: search for an Ask HN post, confirm self-text renders correctly in list and detail view
- [ ] 5.3 Manually verify: empty query, no-match query, and simulated network failure each show the correct state
- [ ] 5.4 Manually verify: scrolling search results loads additional pages
