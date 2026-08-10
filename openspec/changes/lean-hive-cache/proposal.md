## Why

Every article and comment the app fetches to render a list or a thread is currently persisted to Hive in full (title, url, score, text, kids, descendants) and kept forever, regardless of whether the user ever interacts with it. Scrolling the front page or opening one large thread permanently archives everything scrolled past, with no eviction or TTL — on-disk cache grows unbounded with browsing volume instead of with actual user engagement.

## What Changes

- **BREAKING**: The `"news"` Hive box changes from storing full item JSON for every fetched article to storing a lean record (`{id, displayReaderMode, bookmarked}`) only for articles whose reader-mode toggle or bookmark flag has actually been touched by the user. Articles never interacted with get no record at all.
- **BREAKING**: The `"comments"` Hive box changes from caching full comment bodies for every fetched comment to storing a presence-only marker only for comments the user has manually collapsed. Comment bodies are always fetched fresh from the network and never persisted. Re-expanding a comment deletes its record.
- Add a new `"bookmarks"` Hive box, keyed by article id, storing the full item JSON plus a `bookmarkedAt` timestamp for every currently-bookmarked article. This is the one deliberate exception to "lean by default" — it keeps the Saved-For-Later tab instant/offline and gives RSS bookmarks a durable copy of content that may age out of the source feed.
- Remove the `_savedItemsKey` ordered-id-list pattern (a string key mixed into the `"news"` box alongside integer-keyed item records). The new `"bookmarks"` box is read via `box.values` sorted by `bookmarkedAt` descending, replicating today's most-recently-bookmarked-first ordering without a separate index.
- **BREAKING**: Remove `hasBeenRead` entirely from `ItemState`, `ItemUpdater`, and `Store` — it is currently write-only with no UI consumer.
- Field names `displayReaderMode` and `savedForReadLater` are unchanged; this change alters retention behavior, not naming.

Explicitly out of scope: bookmarking a story does not trigger caching of its comment tree; comments remain lean/network-only regardless of the parent article's bookmark state. No TTL/expiry is introduced for lean or bookmark records — bounding relies on records only being written on user interaction.

## Capabilities

### New Capabilities
- `article-storage`: Lean-by-default persistence for articles in the `"news"` box — no record unless reader-mode or bookmark state has been touched, and removal of the unused `hasBeenRead` field.
- `bookmark-storage`: Full-content persistence for bookmarked articles in a dedicated `"bookmarks"` box, including bookmark-time ordering for the Saved-For-Later list.
- `comment-collapse-storage`: Presence-only persistence for manually-collapsed comments in the `"comments"` box, with no comment body ever cached.

### Modified Capabilities
(none — existing specs govern reader-mode runtime behavior, not persistence retention, and are unaffected)

## Impact

- `lib/store/store.dart` — `NewsStore`, `ItemUpdater` mixin, `_savedItemsKey`/`savedItems` list logic, `saveToReadLater`, `markHasBeenRead`
- `lib/models/item.dart` — `ItemState` (drop `hasBeenRead`), lean vs. full serialization for items
- `lib/comments/apis/comments_api.dart` — `CommentsApiRetriever._downloadComment`, `updateComment`, box init
- `lib/comments/views/comments_expansion.dart` — `onExpansionChanged` callback
- `lib/news/apis/news_api.dart` — `SavedArticlesRetriever`, `NewsApiRetriever.getNews`
- `lib/news/bloc/item_bloc.dart` — remove `markHasBeenRead` call site
- `lib/rss/models/rss_story_item.dart` — bookmark rehydration rationale for RSS items
- `lib/rss/store/rss_feeds_store.dart` — existing per-concern Hive box pattern to mirror for the new `"bookmarks"` box
- `lib/main.dart` — open the new `"bookmarks"` box alongside `initNewsStore()` / `initRssFeedsStore()`

No new network calls are introduced; bookmark storage persists content already fetched to render the item.
