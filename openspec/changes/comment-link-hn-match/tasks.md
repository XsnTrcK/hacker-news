## 1. Match verification helper

- [ ] 1.1 Add a pure helper (e.g. in `lib/services/link_handler.dart`) that normalizes a URL to lowercase-host + trailing-slash-stripped path (ignoring query string and fragment) for comparison
- [ ] 1.2 Add a function that takes a tapped URL and an `ItemWithKids?` candidate and returns `true` only when the candidate has a non-null `url` and its normalized hostname+path equals the tapped URL's

## 2. Comment-scoped link resolution

- [ ] 2.1 Add `handleCommentLinkTap(BuildContext context, String? url)` (or equivalent) in `lib/services/link_handler.dart`, separate from the existing shared `handleLinkTap`
- [ ] 2.2 Implement its flow: if `url` is already a `news.ycombinator.com/item?id=` link, delegate to the existing `getItemOrOpenUrl` behavior unchanged; otherwise call `HnSearchApi.findHnItemForUrl(url, httpClient)` wrapped in `.timeout(...)`, run the result through the match-verification helper (task 1.2), and on a verified match push `DisplayArticle(matchedItem)` exactly as the existing HN-item-link path does
- [ ] 2.3 On timeout, error, or no verified match, fall back to the existing external-open behavior (`_openUrl`/`launchUrl`), unchanged from today
- [ ] 2.4 Choose and document the timeout duration for the Algolia lookup

## 3. Pending-check indicator

- [ ] 3.1 Add pending-check state to `Comment`/`comments_section.dart` (or the nearest shared ancestor) sufficient to show a transient banner while a lookup triggered by `handleCommentLinkTap` is in flight
- [ ] 3.2 Show a non-blocking banner/toast (e.g. "Checking for HN discussion…") while pending; ensure the comment thread remains scrollable and interactive during this time
- [ ] 3.3 Dismiss the banner automatically when the lookup resolves (match, no match, error, or timeout)
- [ ] 3.4 Verify concurrent taps on two different comment links each get their own independent lookup/banner lifecycle, without one interfering with the other

## 4. Wiring

- [ ] 4.1 Update `lib/comments/views/comment.dart`'s `Html.onLinkTap` to call `handleCommentLinkTap` instead of the shared `handleLinkTap`
- [ ] 4.2 Confirm `lib/news/views/display_article.dart`'s self-text `Html.onLinkTap` (line ~125) is untouched and still calls the shared `handleLinkTap`

## 5. Verification

- [ ] 5.1 Add/extend unit tests (mirroring `test/link_handler_test.dart`'s style) for the match-verification helper: exact match, query-string/trailing-slash-only differences, hostname mismatch, path mismatch, and no-`url` candidate
- [ ] 5.2 Add/extend unit tests for `handleCommentLinkTap`'s branches: existing HN-item-link passthrough, verified match, no match, lookup error, and timeout — using injectable fetch/open/timeout seams consistent with `LinkHandler`'s existing constructor-injection pattern
- [ ] 5.3 Manually verify: tap a comment link whose URL matches a real HN discussion, confirm the banner appears then the in-app discussion opens
- [ ] 5.4 Manually verify: tap a comment link with no matching discussion (e.g. a generic/unsubmitted URL), confirm the banner appears then the external browser opens as before
- [ ] 5.5 Manually verify: tap a comment link, then tap a second different comment link while the first is still pending, confirm both resolve independently
- [ ] 5.6 Manually verify: an article's self-text links are unaffected (still open externally with no banner, no discussion check)
