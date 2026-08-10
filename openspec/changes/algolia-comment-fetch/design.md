## Context

`CommentsApiRetriever` (`lib/comments/apis/comments_api.dart`) implements the `CommentsHandler` interface: `init`, `fetchComments(ItemWithKids)`, `getComment(id)`, `updateComment(comment)`. It backs a Hive `Box<String>` (`comments`) keyed by comment id, storing each `CommentItem` as `jsonEncode(comment.toMap())`. `fetchComments` walks `itemWithKids.childrenIds` depth-first, calling Firebase's `item/{id}.json` for each node not already in the box, via nested `Future.wait`.

Verified live against `hn.algolia.com/api/v1/items/{id}`:
- One request returns the story plus the fully nested comment tree (tested on a 713-comment thread — all 713 present in one response).
- Each nested comment node has: `id`, `parent_id`, `author`, `created_at_i`, `text`, `children` (recursively, same shape).
- `dead`/`deleted` comments are **not present** in the tree at all. Cross-checked against Firebase: a comment Firebase flags `dead: true` returns 404 from Algolia's `/items/{id}` directly, and is missing from its parent's `children` array (Firebase parent had 4 kids, Algolia's tree had 1). Confirmed with the user this is an acceptable trade-off — no fallback to Firebase to backfill these.
- No `descendants`/`num_comments` count at the top level of `/items/{id}` — irrelevant here since story metadata (including comment count) continues to come from Firebase via the existing `NewsApiRetriever` path, untouched by this change.

## Goals / Non-Goals

**Goals:**
- Replace the N-request recursive comment fetch with a single Algolia request per story.
- Preserve the existing `CommentsHandler` interface, `CommentItem` shape, and Hive cache format exactly — zero changes required in `CommentsBloc`, `comments_expansion.dart`, or `comments_section.dart`.
- Keep Firebase as the sole source for story lists and story metadata (`NewsApiRetriever` is untouched) — this change is scoped to comments only.

**Non-Goals:**
- Backfilling dead/deleted comments from Firebase to paper over Algolia's gap — explicitly accepted as-is.
- Changing how stories themselves are fetched (`top`/`new`/`best`/`ask`/`show`/`job` lists) — that was considered and rejected in favor of keeping Firebase as source of truth (see prior exploration: no exact Algolia equivalent for `best`, and Firebase is the authoritative, real-time source for list membership).
- Real-time comment updates/polling — out of scope, matches current behavior (fetch-once-per-open).

## Decisions

**Always re-fetch the full tree on `fetchComments`, don't reuse the per-comment cache check.** Today, `_downloadComment` skips any comment already in the Hive box, so revisiting a previously-loaded thread costs zero requests unless new comments exist below the cached leaves (which are never checked). With a single bulk call replacing N calls, "skip if cached" no longer saves anything meaningful — the whole point is one request regardless of tree size — and always fetching means revisiting a thread also picks up new comments posted since the last visit. Trade-off: a revisit that used to cost 0 requests (fully cached) now costs 1. Accepted, since 1 request is already cheaper than the *old* fetch could ever be for any thread with new activity.

**Flatten recursively into the existing `CommentItem` list shape.** `fetchComments`'s contract is "return the direct children as `List<CommentItem>`, with all descendants cached and reachable via `getComment(id)`." The new implementation fetches `/items/{storyId}`, then recursively walks the response's `children`, constructing a `CommentItem` per node and writing each to the Hive box (same `toMap()`/`jsonEncode` as today), returning only the top-level `children` as the method's result — preserving the exact same contract `CommentsBloc` and `comments_expansion.dart` already rely on.

**Field mapping** (Algolia node → `CommentItem` constructor `(id, time, createdBy, state, text, childrenIds, parentId, isDeleted, isDead)`):
- `id` ← `id`
- `time` ← `created_at_i`
- `createdBy` ← `author` (coalesce null → `''`, consistent with `ItemMap.createdBy`'s existing `?? ""`)
- `state` ← `ItemState()` (no source data from Algolia; same default used for freshly-fetched Firebase comments today, since Firebase doesn't carry app-local state either — `state` is purely local UI state, not upstream data)
- `text` ← `text` (coalesce null → `''`)
- `childrenIds` ← `children.map((c) => c['id'])`
- `parentId` ← `parent_id`
- `isDeleted` ← `false` (always — Algolia never surfaces these nodes)
- `isDead` ← `false` (always — same reason)

**Swap at the composition root, not behind a feature flag.** `getCommentsHandler()` (`lib/comments/apis/comments_api.dart:85`) is the single place `CommentsHandler` is constructed. Per project convention (CLAUDE.md: no feature flags/backwards-compat shims — just change the code), `CommentsApiRetriever` is replaced outright rather than toggled, and the old Firebase-per-comment implementation is deleted once the new one is in place.

## Risks / Trade-offs

- **Dead/deleted comments silently disappear** → Accepted by the user; no mitigation planned. Comment counts shown on a story (sourced from Firebase's `descendants`) may now read slightly higher than the number of comments actually rendered, since Firebase's count includes dead/deleted nodes Algolia omits. Not fixed by this change.
- **Algolia as a hard dependency for viewing any comments** → If Algolia is down, comments fail to load app-wide (previously a Firebase outage would have the same effect, so this is a lateral dependency shift, not a new single point of failure — the app already required one upstream API to be up for comments).
- **Revisit cost changes from "often free" to "always 1 request"** → Negligible in practice; one request is small relative to the N-request cost it replaces.

## Migration Plan

- Implement `AlgoliaCommentsRetriever`, wire it into `getCommentsHandler()`, delete `CommentsApiRetriever`.
- No Hive migration needed — box schema and key format are unchanged; existing cached comments remain valid and readable, new fetches simply overwrite/add entries in the same format.
- Rollback is a straight revert (swap the composition root back) since nothing about the storage format changed.

## Open Questions

- None outstanding — dead/deleted comment handling was the only open decision and is resolved (accepted as-is).
