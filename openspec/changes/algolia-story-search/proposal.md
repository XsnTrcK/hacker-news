## Why

There is currently no way to search for a story in the app — the only way to find something is to scroll a live feed (Top/New/Best/Ask/Show/Job) or an RSS feed. The HN Algolia Search API (`hn.algolia.com/api/v1`) is already a soft dependency of this app (`lib/rss/apis/hn_search_api.dart` uses it to resolve an RSS item's URL to its HN discussion thread), and it returns story data in a shape that maps directly onto the app's existing `StoryItem`/`AskItem` models — so search can be added by reusing the existing list and detail UI rather than building new rendering code.

## What Changes

- Add a new `AlgoliaStorySearchApi` that queries `GET https://hn.algolia.com/api/v1/search?query=<text>&tags=story` and maps hits to `StoryItem` (or `AskItem` for self-text/Ask HN posts using `story_text`).
- Add a `SearchBloc` (extends `ThrottledBloc`) that takes query text, debounces it, and drives paginated search requests (`page`/`hitsPerPage`), exposing loading/success/empty/failure states analogous to `NewsBloc`.
- Add a search entry point as a `FloatingActionButton` in `HackerNewserNavigation`, visible only when `_feedMode` is `FeedMode.all` or `FeedMode.hn` (hidden in `FeedMode.rss`, and hidden while the Menu page is showing), that pushes a full-screen search view.
- Add a search results view reusing the existing story list rendering (`ImageListItem`) and the existing detail view (`ViewArticles`/`display_article.dart`) — no new item-rendering widgets.
- Scope for this change: story search only, plain query text (no filters), no comment or user search.

## Capabilities

### New Capabilities
- `story-search`: Lets a user search Hacker News stories by keyword from the News page and open a matching story in the existing detail view.

### Modified Capabilities
(none — no existing spec's requirements change; this only adds a new entry point and a new API client)

## Impact

- New files: `lib/search/apis/algolia_story_search_api.dart`, `lib/search/bloc/search_bloc.dart` (+ events/state), `lib/search/views/search_page.dart`.
- Modified files: `lib/components/hacker_newser_navigation.dart` (add search icon/entry point).
- New third-party surface exercised more heavily: `hn.algolia.com` (already contacted today by `hn_search_api.dart`, but only for a narrow lookup — this makes it a user-facing, higher-traffic dependency). No API key or new package required.
- No changes to Hive storage, existing BLoCs, or the Firebase-backed news pipeline.
