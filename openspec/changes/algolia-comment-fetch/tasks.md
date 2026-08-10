## 1. Algolia comments retriever

- [ ] 1.1 Create `lib/comments/apis/algolia_comments_api.dart` with `AlgoliaCommentsRetriever implements CommentsHandler`
- [ ] 1.2 Implement `fetchComments(ItemWithKids)`: call `GET https://hn.algolia.com/api/v1/items/{itemWithKids.id}`, recursively flatten the response's `children` tree into `CommentItem`s per the field mapping in design.md
- [ ] 1.3 Write every flattened `CommentItem` into the existing Hive `comments` box (`jsonEncode(comment.toMap())`), matching `CommentsApiRetriever`'s current storage format exactly
- [ ] 1.4 Return only the top-level `children` as `List<CommentItem>`, matching the existing `fetchComments` contract
- [ ] 1.5 Implement `getComment`/`updateComment`/`init` identically to `CommentsApiRetriever` (same Hive box, same box name `"comments"`)
- [ ] 1.6 Let request failures propagate (no internal try/catch) so `CommentsBloc`'s existing try/catch produces the failure state

## 2. Composition and cleanup

- [ ] 2.1 Update `getCommentsHandler()` in `lib/comments/apis/comments_api.dart` to construct `AlgoliaCommentsRetriever` instead of `CommentsApiRetriever`
- [ ] 2.2 Remove `CommentsApiRetriever` and its Firebase-per-comment recursive fetch (`_downloadComment`, `_fetchComments`) once nothing references them
- [ ] 2.3 Confirm no other code constructs `CommentsApiRetriever` directly (only via `getCommentsHandler()`)

## 3. Verification

- [ ] 3.1 Manually verify: open a story with a large comment thread (100+ comments), confirm it loads via a single network call and renders identically to before
- [ ] 3.2 Manually verify: a story containing at least one dead/deleted comment (e.g. an old, contentious thread) — confirm the thread loads without error and simply omits that comment, matching the accepted behavior
- [ ] 3.3 Manually verify: reopening a previously-viewed story's comments reflects any comments posted since the last visit
- [ ] 3.4 Manually verify: simulate a network failure (e.g. airplane mode) and confirm the comments view shows a failure state without crashing the app
- [ ] 3.5 Confirm existing Hive-cached comments (written by the old retriever) remain readable via `getComment` after the swap
