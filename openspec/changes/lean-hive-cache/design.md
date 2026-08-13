## Context

Hive is used as an unbounded content cache today, not a preferences store. `NewsStore.save()` (`lib/store/store.dart`) writes the full JSON of every article fetched to render any list — top/new/best/ask/show/job — into `Box<String> "news"`, keyed by id, with no eviction. `CommentsApiRetriever._downloadComment()` (`lib/comments/apis/comments_api.dart`) does the same for every comment fetched to render any thread, into `Box<String> "comments"`. Bookmarked-article ids live in a `List<int>` JSON-encoded under a special string key (`_savedItemsKey` = `"savedItems"`) mixed into the same `"news"` box as the integer-keyed item records. `ItemState.hasBeenRead` is written (`item_bloc.dart:35`) but has no UI consumer anywhere.

This design covers three Hive boxes changing shape (`"news"`, new `"bookmarks"`, `"comments"`) and, critically, what happens to data already on users' devices from prior app versions — this app has no server-side migration hook, so the transition has to happen client-side on first launch of the new version.

## Goals / Non-Goals

**Goals:**
- Bound on-disk Hive storage by user interaction (bookmarks, reader-mode toggles, manual comment collapses) instead of by browsing volume.
- Preserve existing bookmarks and their relative order across the migration.
- Preserve existing per-article reader-mode toggle state across the migration where feasible.
- Keep the Saved-For-Later tab's current UX (instant load, most-recently-bookmarked-first) without a network round-trip per item.

**Non-Goals:**
- No TTL/expiry policy for lean or bookmark records.
- No renaming of `displayReaderMode` / `savedForReadLater`.
- No caching of comment trees for bookmarked stories (deferred).
- No offline caching of rendered web page / reader-mode HTML content — only the item JSON already fetched to display it.
- No preservation of previously-collapsed comment state across the migration (see Decisions).

## Decisions

### Bookmark record shape: wrap, don't merge
Store each `"bookmarks"` box entry as `{"bookmarkedAt": <epochMillis>, "item": <Item.toMap()>}` rather than injecting `bookmarkedAt` as a new top-level key into `Item.toMap()` itself. `Item.toMap()`/`Item.fromJson()` define the canonical wire shape shared with the HN API response format; `bookmarkedAt` is a storage-layer concern, not a domain property of an `Item`. Keeping it in a wrapper avoids `Item` needing to know about bookmark bookkeeping at all.

**Alternative considered**: add `bookmarkedAt` directly into `ItemState.toMap()` alongside `displayReaderMode`/`savedForReadLater`. Rejected — `ItemState` is embedded in every item written to the lean `"news"` box too, and a timestamp only meaningful for bookmarked items would leak into every lean record's shape for no reason.

### Reading order: sort in memory, don't maintain an index
`SavedArticlesRetriever` loads `box.values` from `"bookmarks"`, decodes each wrapper, and sorts by `bookmarkedAt` descending on read. No separate ordered-id index is maintained.

**Alternative considered**: keep a `List<int>` index (like today's `_savedItemsKey`) inside the new box for O(1) ordered iteration. Rejected — the whole point of the box split is to stop mixing index bookkeeping with content; a sort-on-read over a box bounded by "however many articles the user has bookmarked" is cheap, and it removes an entire class of index/content divergence bugs (e.g., index says bookmarked, content missing, or vice versa).

### Comment collapse marker: presence-only via `Box<bool>`
The `"comments"` box only ever needs to answer "is this id collapsed?" — there is no second value ever stored. Use `Box<bool>` and treat `containsKey(commentId)` as the read, `put(commentId, true)` as collapse, `delete(commentId)` as re-expand. No JSON encoding involved for this box at all.

**Alternative considered**: keep the existing `Box<String>` and store a JSON blob like today (`{"id":..., "isExpanded": false, "type": "comment"}`) but strip the content fields. Rejected — once the payload is reduced to one boolean that only ever takes one value when present, encoding/decoding JSON for it is pure overhead. Presence-only is both simpler and smaller on disk.

### Migration strategy: forward-migrate bookmarks and reader-mode state, wipe comment cache
On first launch of the version containing this change, run a one-time migration gated by a version flag stored in Hive (e.g., a key in the existing `settings` box, following the pattern `SettingsStore` already establishes):
1. Read the old `_savedItemsKey` list from the `"news"` box. For each id, read its full cached item record, wrap it with a synthetic `bookmarkedAt` that preserves relative order (e.g., `now - index` milliseconds, since the old list is already most-recent-first), and write it to the new `"bookmarks"` box.
2. Scan the remaining entries in the `"news"` box. For each item whose `state.displayReaderMode != null`, write a lean record (`{id, displayReaderMode, bookmarked}`) preserving that toggle. Discard everything else.
3. Delete the old `_savedItemsKey` entry and clear the `"news"` box of any full-content entries not carried forward in steps 1–2.
4. Delete the entire `"comments"` box. Previously-collapsed comment threads reset to expanded; this is an accepted one-time UX regression rather than an ongoing cost — reconstructing which comments were collapsed would require scanning full comment content, which reintroduces the exact bloat this change removes.

**Alternative considered**: wipe all three boxes unconditionally and start clean. Rejected — silently dropping every existing bookmark on upgrade is a much worse user-facing regression than losing collapse state on old threads; bookmarks are the one thing users have deliberately curated and are the entire reason the `"bookmarks"` box exists.

## Risks / Trade-offs

- **[Risk]** The one-time migration scans the full pre-upgrade `"news"` box to recover reader-mode toggles (step 2), and this is exactly the unbounded structure this change exists to eliminate — a heavy user could have tens of thousands of entries. → **Mitigation**: this scan runs exactly once, is a synchronous local key-value iteration (not network-bound), and Hive read throughput for small string values is fast enough (sub-second to low single-digit seconds even at high entry counts) that it's acceptable as a one-time startup cost. No mitigation needed beyond running it once and gating it behind a completed-migration flag.
- **[Risk]** Synthetic `bookmarkedAt` values assigned during migration (`now - index`) don't reflect true historical bookmark time. → **Mitigation**: only relative order matters for the Saved-For-Later tab's UX, and relative order is exactly what's preserved from the old list; no functional impact.
- **[Risk]** Wiping the `"comments"` box loses all previously-collapsed comment state. → **Mitigation**: accepted, one-time, cosmetic only (threads default back to expanded, which is the app's normal default state anyway).
- **[Risk]** If the migration is interrupted (app killed mid-migration), partial state could leave the version flag unset while some data has already moved. → **Mitigation**: order the migration so the version flag is written last, after all box mutations complete; on next launch an interrupted migration simply re-runs (idempotent: re-reading an already-migrated `"news"` box for reader-mode toggles and re-writing the same bookmarks is harmless).

## Migration Plan

1. Ship the new box-writing/reading logic (`article-storage`, `bookmark-storage`, `comment-collapse-storage` capabilities) alongside the one-time migration routine, run during `initNewsStore()` in `lib/main.dart` before any store is used.
2. Migration runs once per install, gated by a flag; no user-visible step, no rollback needed since it only consolidates local data (nothing server-side to coordinate).
3. No rollback strategy is provided for downgrading to a pre-change app version after migration has run — this is a local-only app with no cross-version compatibility guarantee for cache contents, consistent with how the existing codebase treats Hive boxes as disposable/reconstructable from the network.

## Open Questions

None outstanding — all decisions in this document were converged on during exploration prior to this proposal.
