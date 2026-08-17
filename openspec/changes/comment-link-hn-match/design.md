## Context

See proposal.md - Why. Relevant existing code:

- `LinkHandler.getItemOrOpenUrl` (`lib/services/link_handler.dart:63`) is the single chokepoint both `comment.dart` and `display_article.dart`'s self-text `Html` call into via `handleLinkTap`. It already special-cases `news.ycombinator.com/item?id=` URLs (resolves to a `TitledItem`, pushes `DisplayArticle`); everything else falls through to `_openUrl` (`launchUrl`, external).
- `HnSearchApi.findHnItemForUrl` (`lib/rss/apis/hn_search_api.dart`) already does an Algolia `restrictSearchableAttributes: 'url'` lookup and returns `ItemWithKids?` — used today only by `display_article.dart`'s `RssStoryItem` background match in `initState`. `ItemWithKids extends TitledItem`, so a successful result is already the type `DisplayArticle` expects.
- `Comment` (`lib/comments/views/comment.dart`) renders `comment.text` via `flutter_html`'s `Html` widget with `onLinkTap: (url, _, __) => handleLinkTap(context, url)`. `onLinkTap` is a plain callback — there is no per-`<a>`-span handle to imperatively update just the tapped link's appearance.

## Goals / Non-Goals

**Goals:**
- Reuse `HnSearchApi.findHnItemForUrl` unchanged — no changes to its existing RSS call site or contract.
- Keep the change scoped to comment-originated taps only; `display_article.dart`'s self-text link handling must be provably untouched.
- Match the existing silent-swap UX already used for `news.ycombinator.com/item?id=` links.
- Bound worst-case latency with a timeout so a tap always resolves to an outcome.

**Non-Goals:**
- Article self-text links (out of scope per proposal).
- Any change to `algolia-story-search` (separate, unrelated change) — this does not depend on or block it.
- Caching/memoizing lookup results across taps or sessions.
- Fuzzy/partial URL matching or a "possible match, are you sure?" UI — match is binary (verified hostname+path equality) or treated as no match.

## Decisions

### Comment-scoped entry point, not a flag on the shared `handleLinkTap`
Add a comment-specific wrapper (e.g. `handleCommentLinkTap(context, url)`) that `comment.dart` calls instead of the shared `handleLinkTap`, rather than adding a `bool fromComment` parameter to the existing shared function.

- Alternative considered: thread a `fromComment` flag through `handleLinkTap`/`getItemOrOpenUrl`. Rejected — it forces every call site (including `display_article.dart`'s self-text, and any future caller) to state the flag, and makes "is this comment-scoped behavior active" implicit in a boolean rather than explicit at the call site. A dedicated wrapper makes `display_article.dart:125`'s call site provably unchanged by this diff.

### Match verification lives at the comment-tap call site, not inside `HnSearchApi`
The hostname+path normalization/comparison is a small pure helper invoked after `HnSearchApi.findHnItemForUrl` returns, not a change to `findHnItemForUrl` itself.

- Alternative considered: add a `verifyUrl` param to `findHnItemForUrl` so both RSS and comment callers could opt in/out. Rejected — RSS's existing background match in `display_article.dart:62` has different risk tolerance (curator-picked feed URLs, background load, not user-tap-triggered) and is out of scope for this change; changing `findHnItemForUrl`'s contract risks altering already-shipped, untested-by-this-change RSS behavior. Keeping verification external leaves RSS completely untouched.

### Timeout via `Future.timeout` at the call site
Wrap the `HnSearchApi.findHnItemForUrl` call (plus verification) with `.timeout(...)`; catch both `TimeoutException` and any other error identically, both collapsing to "no match, open externally." One error path, matching the spec's "fails or times out" scenario exactly.

### Pending-check indication: transient non-blocking banner
Per user decision, use a transient banner/toast-style indicator (e.g. an `InfoBar`/`SnackBar`-equivalent in this app's Fluent UI) shown while the lookup is in flight, dismissed automatically on resolution. The comment thread remains scrollable/interactive throughout — this is a state flag surfaced near the top or bottom of the comments view, not a modal, and not an inline change to the tapped `<a>` span (which `flutter_html`'s `onLinkTap` callback has no hook to update directly).

- Alternative considered: blocking modal `ProgressRing` overlay. Rejected by user — simpler state machine, but freezes the whole screen for a lookup that's often fast and shouldn't interrupt reading.
- Alternative considered: rewriting the comment's rendered HTML to swap the tapped anchor's own text/style. Rejected — `flutter_html` provides no imperative per-span update hook from within `onLinkTap`; would require re-parsing/re-rendering the whole comment body per tap, disproportionate to the payoff.

## Risks / Trade-offs

- **Latency on every non-HN comment-link tap**: every such tap now costs a network round trip before anything opens. Mitigated by the timeout (bounded worst case) and the non-blocking banner (user isn't stuck watching a frozen screen).
- **Concurrent taps**: a user could tap a second comment link while the first lookup is still pending. Each tap's lookup and banner are independent (not globally serialized); this is acceptable given lookups are short and bounded, and avoids adding queuing complexity for an edge case.
- **False negatives from normalization choices**: normalizing away query strings could occasionally accept a match that's actually a different page on sites where the path alone doesn't disambiguate content (e.g. some SPA routes keyed entirely by query param). Accepted trade-off — same class of risk the proposal already weighed when choosing hostname+path over exact string match, and still strictly tighter than the RSS path's current "trust `hits.first`" behavior.
