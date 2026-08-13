## 1. Data model cleanup

- [ ] 1.1 Remove `hasBeenRead` from `ItemState` (field, `fromJson`, `toMap`) in `lib/models/item.dart`
- [ ] 1.2 Remove `hasBeenRead`/`markHasBeenRead` from `ItemUpdater` mixin and `Store`/`NewsStore` in `lib/store/store.dart`
- [ ] 1.3 Remove the `markHasBeenRead` call and its triggering event handling in `lib/news/bloc/item_bloc.dart`
- [ ] 1.4 Add a lean serialization path for `Item`/`ItemState` (e.g. a `toLeanMap()`/lean decode helper producing `{id, displayReaderMode, bookmarked}`) alongside the existing full `toMap()`/`fromJson()`, without changing the full shape's field names

## 2. Bookmark storage (new "bookmarks" box)

- [ ] 2.1 Create a bookmarks store module mirroring the `RssFeedsStore` pattern (`lib/rss/store/rss_feeds_store.dart`) that opens `Box<String> "bookmarks"`
- [ ] 2.2 Implement write: on bookmark, encode `{"bookmarkedAt": <epochMillis>, "item": <Item.toMap()>}` and `put` under the article id
- [ ] 2.3 Implement delete: on unbookmark, remove the entry for that article id
- [ ] 2.4 Implement ordered read: load all entries, decode, sort by `bookmarkedAt` descending
- [ ] 2.5 Update `NewsStore.saveToReadLater` (`lib/store/store.dart`) to call the new bookmarks store instead of maintaining the `_savedItemsKey` list
- [ ] 2.6 Remove `_savedItemsKey`/`savedItems` list logic from `lib/store/store.dart`
- [ ] 2.7 Update `SavedArticlesRetriever` (`lib/news/apis/news_api.dart`) to read from the bookmarks store's ordered list instead of `newsStore.savedItems` + `newsStore.containsKey`/`get`
- [ ] 2.8 Open the `"bookmarks"` box during startup in `lib/main.dart`, alongside `initNewsStore()`/`initRssFeedsStore()`

## 3. Lean article storage ("news" box)

- [ ] 3.1 Update `NewsStore.save()` (`lib/store/store.dart`) to write nothing when neither `displayReaderMode` nor `bookmarked` has been touched
- [ ] 3.2 Update `NewsStore.save()` to write a lean `{id, displayReaderMode, bookmarked}` record when either has been touched, regardless of full-content storage in the bookmarks box
- [ ] 3.3 Update `NewsStore.containsKey`/`get` to read/hydrate from the lean record shape rather than assuming full content is present
- [ ] 3.4 Update `NewsApiRetriever.getNews` (`lib/news/apis/news_api.dart`) call sites that assumed `newsStore.get()` returns a fully-populated item, so list rendering uses the freshly-fetched network item rather than expecting the store to supply title/url/score

## 4. Comment collapse storage ("comments" box)

- [ ] 4.1 Change `CommentsApiRetriever`'s box (`lib/comments/apis/comments_api.dart`) to `Box<bool>` used purely as a presence marker
- [ ] 4.2 Remove the unconditional full-content `put` in `_downloadComment`; always fetch comment content from the network
- [ ] 4.3 Add collapse/expand methods: `put(commentId, true)` to collapse, `delete(commentId)` to re-expand, replacing the current `updateComment(CommentItem)` full-object write
- [ ] 4.4 After fetching a comment from the network, set `state.isExpanded = false` if `containsKey(commentId)` is true, otherwise leave the default `true`
- [ ] 4.5 Update `onExpansionChanged` in `lib/comments/views/comments_expansion.dart` to call the new collapse/expand methods instead of mutating `comment.state.isExpanded` and calling `updateComment`

## 5. One-time migration

- [ ] 5.1 Add a migration-complete flag key (e.g. in the existing `"settings"` box, following `SettingsStore`'s key pattern in `lib/store/settings_store.dart`)
- [ ] 5.2 Implement migration step: read the old `_savedItemsKey` list and each referenced full item record, write each into the new `"bookmarks"` box with a synthetic `bookmarkedAt` that preserves the original relative order
- [ ] 5.3 Implement migration step: scan remaining `"news"` box entries, and for each with a non-null `displayReaderMode`, write the equivalent lean record
- [ ] 5.4 Implement migration step: clear the old `_savedItemsKey` entry and any full-content `"news"` box entries not carried forward
- [ ] 5.5 Implement migration step: delete all entries in the `"comments"` box
- [ ] 5.6 Set the migration-complete flag only after all prior steps succeed, so an interrupted migration safely re-runs and is idempotent
- [ ] 5.7 Wire the migration to run once during startup in `lib/main.dart`, before `initNewsStore()`/`getCommentsHandler().init()` are used elsewhere

## 6. Tests

- [ ] 6.1 Add tests for lean article write/skip behavior in `NewsStore.save()` (untouched article → no record; reader-mode-only → lean record; bookmark-only → lean record)
- [ ] 6.2 Add tests for the bookmarks store: write on bookmark, delete on unbookmark, descending-by-`bookmarkedAt` ordered read
- [ ] 6.3 Add tests for `SavedArticlesRetriever` reading from the bookmarks store without hitting the network for already-bookmarked items
- [ ] 6.4 Add tests for comment collapse presence-only behavior: collapse writes marker, expand deletes it, untouched comments have no record, comment content is never persisted
- [ ] 6.5 Add tests for the one-time migration: bookmark order preserved, reader-mode toggles preserved, `"comments"` box cleared, migration does not re-run on a second launch, migration is idempotent if interrupted and re-triggered
- [ ] 6.6 Add a regression check that `hasBeenRead` no longer appears anywhere in `ItemState`'s serialized form
