## Why

Comment bodies frequently link to external articles that already have their own HN discussion (the same URL submitted separately, sometimes with more comments than the thread the link was found in). Today every such link leaves the app via the OS browser, even when an in-app HN discussion for that exact URL exists. The app already has this exact lookup built for RSS items (`HnSearchApi.findHnItemForUrl`, used by `display_article.dart` to match an `RssStoryItem`'s URL to its HN thread) — comment links are the same problem, just triggered by a tap instead of a page load.

## What Changes

- Extend the link-resolution chokepoint (`LinkHandler.getItemOrOpenUrl` in `lib/services/link_handler.dart`) with a new fallback branch, scoped to links tapped from comment bodies only: for a URL that isn't already a `news.ycombinator.com/item?id=` link, query `HnSearchApi.findHnItemForUrl` before giving up and launching externally.
- Verify match quality before trusting a hit: the matched item must be an `ItemWithKids` with a non-null `url`, and that `url`'s normalized hostname+path (lowercased host, trailing slash/query/fragment stripped) must equal the tapped URL's normalized hostname+path. No `url` (e.g. Ask/Poll), no match, or a mismatched path is treated as no match.
- Bound the lookup's latency: while it's in flight, show a spinner on the tapped comment link; on timeout, treat it as no match.
- On a verified match, navigate to `DisplayArticle(matchedItem)` — the same silent swap the existing `news.ycombinator.com/item?id=` path already performs, reusing the existing `_buildArticle`/`DisplayArticle` flow with no new UI screen.
- No new API client: reuses `HnSearchApi.findHnItemForUrl` as-is.
- Out of scope: links tapped in article self-text (`display_article.dart`'s `textHtml`) keep today's behavior (`launchUrl` only) — this change targets comment bodies only.

## Capabilities

### New Capabilities
- `comment-link-hn-match`: When a user taps an external link inside a comment body, the app checks (via Algolia, hostname+path verified) whether that URL already has an HN discussion, and if so opens the in-app discussion instead of leaving the app.

### Modified Capabilities
(none — `LinkHandler.getItemOrOpenUrl`'s existing `news.ycombinator.com/item?id=` resolution behavior is unspecced and untouched by this change; only the new comment-link fallback is being specified)

## Impact

- Modified files: `lib/services/link_handler.dart` (new fallback branch, scoped to comment-originated taps), `lib/comments/views/comment.dart` (pending/spinner state around the link tap).
- Untouched: `lib/rss/apis/hn_search_api.dart` (reused as-is), `lib/news/views/display_article.dart` (article self-text link behavior unchanged).
- New third-party traffic: comment link taps now contact `hn.algolia.com` (already contacted today for RSS matching, and by the separate in-progress `algolia-story-search` change).
- No new packages, no Hive/storage changes.
