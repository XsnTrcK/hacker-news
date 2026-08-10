## Why

Opening a story's comments currently costs one HTTP request per comment: `CommentsApiRetriever.fetchComments` walks the tree depth-first, issuing a Firebase `item/{id}.json` request for every node (`lib/comments/apis/comments_api.dart:57`). A popular thread with hundreds of comments means hundreds of round-trips before the thread is fully loaded. Algolia's `GET /v1/items/{id}` returns a story's entire comment tree — fully nested, all fields included — in a single response, verified live against a 713-comment thread. Swapping the comment-fetch step to Algolia turns hundreds of requests into one, without touching how stories are listed or fetched (that stays on Firebase, per the earlier exploration that ruled out a full switch — Firebase remains the only source with exact parity for `best`/`job` and guaranteed freshness).

## What Changes

- Add a new `AlgoliaCommentsRetriever implements CommentsHandler` that fetches `GET https://hn.algolia.com/api/v1/items/{storyId}` once and flattens the nested `children` tree into the existing `CommentItem` list, instead of recursively fetching one comment at a time from Firebase.
- Swap `CommentsApiRetriever` for `AlgoliaCommentsRetriever` at the `getCommentsHandler()` composition point (`lib/comments/apis/comments_api.dart:85`) — `CommentsBloc`, `comments_expansion.dart`, and the Hive-backed comments cache are unaffected since they only depend on the `CommentsHandler` interface and `CommentItem`'s existing shape.
- **BREAKING (behavioral, not API)**: comments that Hacker News marks `dead`/`deleted` will no longer appear at all — Algolia's index omits them entirely (verified: a Firebase-confirmed `dead: true` comment 404s on Algolia and is absent from its parent's `children` array). Today these render as `[dead]`/`[deleted]` placeholders; going forward they're silently missing from the tree. Confirmed acceptable — no Firebase fallback for this gap.
- Story metadata (title, url, score, list membership) is unaffected — this change only touches the comment-fetch step, which runs after a story is already loaded from Firebase.

## Capabilities

### New Capabilities
- `comment-tree-loading`: Defines how a story's comment tree is fetched and cached once a story is opened, including the accepted behavior around dead/deleted comments.

### Modified Capabilities
(none — no existing spec covers comment fetching today; this is undocumented implementation behavior being formalized as a new capability)

## Impact

- New file: `lib/comments/apis/algolia_comments_api.dart` (or equivalent) implementing `CommentsHandler`.
- Modified: `lib/comments/apis/comments_api.dart` composition root (`getCommentsHandler`) to use the new retriever; `CommentsApiRetriever`/Firebase-per-comment path can be removed once replaced (no other caller depends on it directly).
- No change to `lib/comments/bloc/comments_bloc.dart`, `lib/comments/views/*`, or the Hive `comments` box schema — `CommentItem.toMap()` output shape is unchanged, so cached data written under the old retriever remains readable.
- New third-party surface: `hn.algolia.com/v1/items/{id}` becomes a hard dependency for viewing comments (previously only a soft dependency via RSS URL matching and, if the search proposal ships, story search).
- User-visible behavior change: dead/deleted comments disappear from threads instead of showing a placeholder.
