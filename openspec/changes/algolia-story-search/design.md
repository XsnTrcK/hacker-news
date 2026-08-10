## Context

The app has no search today. It already talks to Algolia's HN Search API in one narrow place (`lib/rss/apis/hn_search_api.dart`, `findHnItemForUrl`) to resolve an RSS item's URL to a HN discussion thread for comments. That call proved the endpoint needs no API key and returns usable data; this change generalizes it into a user-facing search feature.

The app has no `AppBar`/`CommandBar` today. `HackerNewserNavigation` (`lib/components/hacker_newser_navigation.dart`) wraps a Material `Scaffold` around a `PageView` (`Menu`, then the News page built by `_buildNewsPage`), with `_feedMode` (`FeedMode.all` / `FeedMode.hn` / `FeedMode.rss`) tracked as state and driving both the story-fetch mode and a bottom `NavigationBar` selection. `Scaffold.floatingActionButton` is unused today.

Verified live against `hn.algolia.com/api/v1/search?query=<text>&tags=story`:
- Hit fields: `objectID`/`story_id` (int), `title`, `url`, `points`, `author`, `created_at_i` (unix seconds), `num_comments`, `children` (flat `List<int>` of comment ids), and `story_text` on Ask HN hits.
- No API key required. `page`/`hitsPerPage` control pagination; `hitsPerPage` accepted values up to 1000 in testing.
- Response also includes `nbHits`/`nbPages`, usable to know when there are no more pages.

## Goals / Non-Goals

**Goals:**
- Let a user search HN stories by keyword and open a result in the existing detail view, with zero new item-rendering widgets.
- Keep the feature isolated: no changes to the Firebase-backed news pipeline, existing BLoCs, or Hive schemas.
- Handle Algolia unavailability gracefully (empty/error state, not a crash), consistent with `HnSearchApi`'s existing try/catch.

**Non-Goals:**
- Comment search, user search, or any filter beyond plain query text (points/date filters are a possible future iteration, not this change).
- Persisting search history or offline caching of search results.
- Changing how the main news feeds are fetched (that's the separate `algolia-comment-fetch` change).

## Decisions

**New `lib/search/` module, not folded into `lib/rss/`.** `hn_search_api.dart` is RSS-specific plumbing (URL → HN item lookup for the comments-matching feature). Story search is a first-class, independently-scoped feature reusing the same upstream API, so it gets its own module mirroring the existing `lib/rss/`, `lib/news/`, `lib/comments/` structure: `lib/search/apis/`, `lib/search/bloc/`, `lib/search/views/`.

**Map Algolia hits to `StoryItem`/`AskItem` directly, not a new model.** This is the same piggyback pattern already used for RSS (`RssStoryItem extends StoryItem`, per project convention). A hit becomes:
- `StoryItem(id: story_id, time: created_at_i, createdBy: author, state: ItemState(), title, score: points, childrenIds: children, numberOfChildren: num_comments, url)` when `story_text` is absent.
- `AskItem` (same fields minus `url`, plus `text: story_text`) when `story_text` is present (Ask HN / self-text posts).
`state` has no source data from Algolia, so it defaults via `ItemState()` (unexpanded, unread, not saved) — the same default the constructor already uses elsewhere for freshly-fetched items.

**Debounce in the UI layer, not the bloc.** `ThrottledBloc`'s 100ms `throttleDroppable` exists to coalesce rapid *scroll/pagination* events, not to rate-limit a text field. Debouncing keystrokes (e.g. 300-400ms) belongs in the search view before a `SearchQueryChanged` event is dispatched, so the bloc's existing throttle semantics aren't repurposed for a different concern. The bloc still applies its normal throttle to the resulting event stream.

**Pagination via `page`, not `offset`.** `NewsApi.getNews` uses `offset`/`count` because Firebase's story-ID lists are fetched once and paged client-side. Algolia's `/search` is server-side paginated via `page`/`hitsPerPage`, which don't translate 1:1 to `offset`. Rather than force-fit `NewsApi`'s contract, `AlgoliaStorySearchApi` gets its own small interface (`search(query, {page})`) — it isn't a `NewsApi` implementation, it's a sibling API client returning the same `TitledItem` list shape so `SearchBloc` can still hand results to `ImageListItem`/`ViewArticles` unchanged.

**Search entry point: `Scaffold.floatingActionButton` in `HackerNewserNavigation`, gated on `_feedMode`.** Set `floatingActionButton: (_feedMode == FeedMode.all || _feedMode == FeedMode.hn) ? FloatingActionButton(...) : null` in `_HackerNewserNavigationState.build`. Tapping it pushes a full-screen `SearchPage` (same `CupertinoPageRoute` + `ColorfulSafeArea` pattern used by `Menu._handleClick`). Chosen over a `Menu` entry per prior discussion — search is a verb tied to the News page, not a standing destination like RSS Feeds/Settings — and scoped to HN-backed feed modes only, since Algolia search covers HN stories, not the user's RSS feeds (`FeedMode.rss` gets no FAB).

Because `Scaffold` wraps the whole `PageView` (both `Menu` at index 0 and the news page at index 1), gating on `_feedMode` alone isn't sufficient: `_feedMode` defaults to `FeedMode.all`/`FeedMode.hn` even while the `Menu` page is showing, so the FAB would float over the menu too. The implementation must also track which `PageView` page is current (e.g. a `PageController` listener or `onPageChanged`, currently absent) and additionally require the news page to be active before showing the FAB.

## Risks / Trade-offs

- **Algolia availability** → Feature already assumes Algolia as a soft dependency (RSS comment-matching); this raises it to a hard dependency for search specifically, but failure only degrades the new search screen (empty/error state), not the rest of the app.
- **No API key / no documented rate limit** → If usage triggers throttling, requests fail visibly (caught, shown as error state) rather than silently corrupting other state; no retry/backoff planned for v1.
- **Result staleness** → Algolia index lag was measured at under two minutes in testing, acceptable for search (unlike a live "New" feed where freshness matters more).

## Migration Plan

Additive only — no existing data, API, or UI is changed. Ships as a new entry point; can be removed by deleting the new files and the `floatingActionButton` addition with no cleanup elsewhere.

## Open Questions

- Should empty-query state show recent/trending stories (e.g. `tags=front_page`) or just a blank prompt? Deferred to implementation — not spec-critical.
- Exact debounce duration (300ms vs 400ms) — implementation detail, not a requirement.
