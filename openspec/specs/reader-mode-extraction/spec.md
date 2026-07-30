# Spec: Reader Mode Extraction

## Purpose

Defines how the app extracts article content for reader mode using the Mozilla Readability.js library injected into the webview page context. This includes readability pre-checks, local asset bundling, DOM isolation, metadata rendering, and post-extraction HTML cleanup.
## Requirements
### Requirement: Readability.js-based content extraction
The system SHALL extract article content for reader mode by injecting the bundled Readability.js library into the webview page context via `runJavaScriptReturningResult` and calling `new Readability(document.cloneNode(true)).parse()`.

#### Scenario: Successful extraction on article page
- **WHEN** reader mode is enabled and a page finishes loading
- **THEN** Readability.js is injected and parses the page
- **AND** the `content` field from the parsed result is used as the reader view HTML

#### Scenario: Readability returns null
- **WHEN** Readability.js cannot identify article content (returns null)
- **THEN** reader mode SHALL not activate and the webview SHALL remain on the original page

### Requirement: isProbablyReaderable pre-check
The system SHALL call `isProbablyReaderable(document)` before injecting or running Readability to determine whether the page is likely to yield a meaningful parse result.

#### Scenario: Page passes readability check
- **WHEN** `isProbablyReaderable(document)` returns true
- **THEN** the system SHALL proceed with full Readability.js extraction

#### Scenario: Page fails readability check
- **WHEN** `isProbablyReaderable(document)` returns false
- **THEN** the system SHALL skip Readability extraction entirely
- **AND** reader mode SHALL not activate for that page

### Requirement: Local asset bundling for Readability.js
The system SHALL bundle `Readability.js` and `Readability-readerable.js` concatenated as a single asset (`assets/readability-bundle.js`) loaded via `rootBundle.loadString` at widget initialization and injected once per page load.

#### Scenario: Offline usage
- **WHEN** the device has no network connection and reader mode is toggled
- **THEN** the Readability bundle SHALL still be available and content extraction SHALL proceed normally

#### Scenario: Page with restrictive Content Security Policy
- **WHEN** a page sets CSP headers that block external scripts
- **THEN** bundle injection via `runJavaScriptReturningResult` SHALL succeed because native JS injection bypasses page CSP

### Requirement: DOM isolation during extraction
The system SHALL pass a deep clone of the document (`document.cloneNode(true)`) to Readability to prevent mutation of the live rendered DOM.

#### Scenario: Reader mode toggled off after extraction
- **WHEN** the user disables reader mode after Readability has parsed the page
- **THEN** the original page SHALL reload cleanly without DOM corruption artifacts

### Requirement: Article metadata header in reader view
When Readability successfully parses a page, the system SHALL prepend a metadata header to the extracted `content` HTML containing the article `title` as an `<h1>` element and `byline` as a `<p>` element when present.

#### Scenario: Article with title and byline
- **WHEN** Readability parse result contains non-empty `title` and `byline`
- **THEN** the reader view SHALL prepend `<h1>{title}</h1><p>{byline}</p>` before the content HTML

#### Scenario: Article with title only
- **WHEN** Readability parse result contains `title` but empty or null `byline`
- **THEN** the reader view SHALL prepend only `<h1>{title}</h1>` before the content HTML

### Requirement: Simplified post-extraction HTML cleanup
When Readability successfully extracts content, the system SHALL skip nav-tag removal since Readability output does not contain navigation elements.

#### Scenario: Readability output applied to reader view
- **WHEN** Readability returns a non-empty `content` string
- **THEN** only the inline style stripper (`_localStyleRegExp`) MAY be applied
- **AND** no `<nav>` regex pass is performed on the Readability output

### Requirement: Concurrent `onPageFinished` invocations are serialized
`WebViewCarrier._onPageFinished` SHALL be re-entrant-safe with respect to both a second `onPageFinished` invocation and a concurrent `onWebResourceError` callback. If a second invocation is triggered (e.g., by an HTTP → HTTPS redirect) while the first is suspended at an `await` point, the second invocation SHALL return immediately without injecting the Readability bundle, running `isProbablyReaderable`, or calling Readability. Only the first invocation completes the extraction. If `onWebResourceError` fires for the main frame while an `_onPageFinished` extraction is still in flight (suspended at any `await` point), the in-flight extraction SHALL check for the error-set terminal state before writing `cachedIsReaderable`/`cachedReaderHtml` or firing `onReadabilityDetermined`/`onLoadComplete` again, so the two code paths cannot overwrite each other's result or invoke callbacks with contradictory values.

#### Scenario: Redirect triggers double `onPageFinished`
- **WHEN** a page redirects from HTTP to HTTPS and `onPageFinished` fires for both the original and redirect URLs before the first extraction completes
- **THEN** the Readability bundle is injected exactly once, `isProbablyReaderable` is called exactly once, and `onReadabilityDetermined` fires exactly once

#### Scenario: Single page load without redirect
- **WHEN** `onPageFinished` fires exactly once for a page
- **THEN** extraction proceeds normally with no change to the happy-path behaviour

#### Scenario: Main-frame error races with in-flight extraction
- **WHEN** `onWebResourceError` fires for the main frame while a prior `_onPageFinished` invocation is still suspended at an `await` (e.g., awaiting the Readability bundle or a `_runJs` call)
- **THEN** `cachedIsReaderable` is set to `false` by the error handler, and the in-flight extraction MUST NOT overwrite `cachedIsReaderable` or invoke `onReadabilityDetermined`/`onLoadComplete` again once the error has already resolved the page's readability state

### Requirement: Readability failure state resets on subsequent navigation
`WebViewCarrier` SHALL track the fragment-stripped URL (`_extractedForUrl`) that its `cachedReaderHtml`/`cachedIsReaderable` were extracted for. At the start of `_onPageFinished`, before the existing short-circuit guard, the carrier SHALL compare the just-finished page's fragment-stripped URL against `_extractedForUrl`; if they differ, the carrier SHALL reset `cachedIsReaderable`, `cachedReaderHtml`, and `_extractedForUrl` to `null` before the guard runs, so the subsequent analysis is not short-circuited by a cache belonging to a different page.

When `WebViewCarrier.loadOriginal()` is called to reload the underlying page, it SHALL reset `cachedIsReaderable` (and `_extractedForUrl`) to `null` only when `cachedReaderHtml` is `null` — i.e., when there is no successful extraction to preserve, whether because analysis never completed or because the last attempt failed. When `cachedReaderHtml` is non-`null` (a successful extraction already exists for the carrier's `resolvedUrl`), `loadOriginal()` SHALL leave the cache untouched, since the reload targets the same URL the cache was extracted for.

#### Scenario: Retry after a failed first pass
- **WHEN** a page's first `onPageFinished` analysis concludes `cachedIsReaderable == false` (e.g., due to a premature check on unhydrated SPA content), and the page later reloads via `loadOriginal()`
- **THEN** `loadOriginal()` resets `cachedIsReaderable` to `null` before reloading, and the next `onPageFinished` for that navigation re-runs `isProbablyReaderable` and, if applicable, the full Readability parse — it is not skipped by the earlier `false` result

#### Scenario: Successful extraction survives a same-URL reload
- **WHEN** `cachedReaderHtml` is already populated from a successful extraction of the carrier's `resolvedUrl`, and `loadOriginal()` is called to reload that same URL
- **THEN** `loadOriginal()` does not clear `cachedReaderHtml`/`cachedIsReaderable`, and the subsequent `onPageFinished` invocation continues to short-circuit as before, avoiding redundant bundle injection and Readability re-parsing

#### Scenario: Cache invalidated when the loaded page's URL differs from the cached URL
- **WHEN** `cachedReaderHtml` is populated for one URL and `_onPageFinished` fires for a page whose fragment-stripped URL differs from `_extractedForUrl` (e.g., the user clicked a link inside the rendered reader HTML and the webview navigated to a different page)
- **THEN** the carrier resets `cachedReaderHtml`, `cachedIsReaderable`, and `_extractedForUrl` to `null` before evaluating the short-circuit guard, so a fresh `isProbablyReaderable`/Readability analysis runs for the newly-loaded page

### Requirement: `loadOriginal()` and `loadReaderHtml()` target the currently-extracted URL
`WebViewCarrier.loadOriginal()` SHALL reload `_extractedForUrl` when it is non-`null`, falling back to `resolvedUrl` only when no extraction has occurred yet. `WebViewCarrier.loadReaderHtml()` SHALL set its `baseUrl` to `_extractedForUrl` when non-`null`, falling back to `resolvedUrl` otherwise. Neither method SHALL unconditionally target the carrier's fixed `resolvedUrl`, since the cache — and therefore the page currently being displayed in reader mode — may belong to a different URL than the carrier's original one.

#### Scenario: Toggling reader mode off after navigating away reloads the current page, not the original article
- **WHEN** the webview has navigated to a different page than the carrier's `resolvedUrl`, reader content has been extracted from that page (`_extractedForUrl` matches it), and `loadOriginal()` is called
- **THEN** the webview reloads `_extractedForUrl` (the page the user is actually viewing), not `resolvedUrl`

#### Scenario: Toggling reader mode at the original article is unaffected
- **WHEN** the webview is displaying the carrier's own `resolvedUrl` and reader content was extracted from it, and `loadOriginal()` is called
- **THEN** `_extractedForUrl` equals `resolvedUrl`, so the webview reloads `resolvedUrl` exactly as before — no behavior change for the at-home case

#### Scenario: Reader HTML resolves relative links against the page it was extracted from
- **WHEN** reader HTML extracted from a navigated-to page is loaded via `loadReaderHtml()`
- **THEN** `baseUrl` is set to that page's URL (`_extractedForUrl`), not the carrier's `resolvedUrl`, so relative links and images in the reader content resolve against the correct page

### Requirement: Cache invalidation happens at navigation-start, not only at load-complete
`WebViewCarrier` SHALL apply the same fragment-stripped `_extractedForUrl` comparison described above inside its `onUrlChange` handler, in addition to `_onPageFinished`. When the webview's reported URL (fragment-stripped) differs from `_extractedForUrl`, the carrier SHALL reset `cachedReaderHtml`, `cachedIsReaderable`, and `_extractedForUrl` to `null` immediately, before forwarding the URL change to `onUrlChanged`. This exists because navigation-start (`onUrlChange`) fires — and any downstream reaction to it propagates — before navigation-complete (`onPageFinished`) has a chance to run its own invalidation check; without an eager check, code reacting to the navigation (e.g. a toggle press, or a persisted-state restore) could read a stale, not-yet-invalidated cache belonging to the previous page.

#### Scenario: Toggling reader mode immediately after linking away does not show stale content
- **WHEN** the user clicks a link inside reader-mode HTML and, before the newly-loaded page's `onPageFinished` analysis completes, triggers a reader-mode toggle
- **THEN** `hasReaderHtml` reports `false` (the previous page's cache was invalidated at `onUrlChange` time), so no stale content is displayed; the toggle takes effect once the new page's own analysis completes

#### Scenario: Returning to the original article via native back-navigation reflects a fresh analysis
- **WHEN** the user taps the in-webview back button and the webview navigates back to the carrier's own `resolvedUrl`
- **THEN** the cache is invalidated at `onUrlChange` time (before any reader-mode display logic reacts to the navigation), and the subsequent `onPageFinished` for the original article performs a fresh extraction rather than exposing a stale cache from the page that was navigated away to

### Requirement: `displayReaderMode` is mutable and kept in sync with the current toggle value
`WebViewCarrier.displayReaderMode` SHALL be a mutable field, not fixed at construction. The field governs two optimizations inside `_onPageFinished`: dismissing the loading spinner early when its value is `false`, and skipping the cheap `isProbablyReaderable` pre-check when its value is non-`null` (already known) rather than running full Readability regardless. Because the same carrier instance persists across in-page link navigation, callers SHALL update this field whenever the current sticky reader-mode value changes, so that analysis triggered by later navigation consults the current value rather than the value present at carrier construction. `WebViewCarrier` SHALL also expose the URL its cache is currently scoped to via a public `extractedForUrl` getter, so callers can distinguish a genuine navigation from the carrier's own `loadReaderHtml()`/`loadOriginal()` calls settling.

#### Scenario: Toggling reader mode mid-session affects the next navigation's analysis
- **WHEN** a carrier was constructed with `displayReaderMode` undetermined or a stale value, and the caller updates `displayReaderMode` after the user toggles reader mode
- **THEN** the next `_onPageFinished` invocation (triggered by a subsequent link navigation) reads the updated value, not the value present when the carrier was constructed

#### Scenario: Standalone carrier construction is unaffected
- **WHEN** a `MobileWebView` with no externally-supplied carrier constructs a fresh `WebViewCarrier`
- **THEN** it is still constructed with `displayReaderMode` left undetermined (`null`), preserving the existing first-visit auto-activate and cheap-pre-check behavior; only the mutable field's *later* updates are new

### Requirement: A main-frame load error does not assert a readability result
`WebViewCarrier.onWebResourceError` SHALL NOT set `cachedIsReaderable` or invoke `onReadabilityDetermined` when a main-frame error occurs. It SHALL only invoke `onLoadComplete` (when not already `isReady`), so a loading indicator that would otherwise hang indefinitely (because a failed main frame never reaches `onPageFinished`) is still cleared. A load failure is not a determination about the page's content, and SHALL NOT overwrite an existing successful determination for that URL.

#### Scenario: A main-frame error does not overwrite a known-good result
- **WHEN** `cachedIsReaderable` already reflects a successful determination for a URL from an earlier load, and a main-frame `WebResourceError` later occurs while re-navigating to that same URL (e.g. via native back-navigation) before `onPageFinished` fires again
- **THEN** `cachedIsReaderable` is left unset by the error (its value depends only on the eager `onUrlChange`-time invalidation and any subsequent `onPageFinished`), and `onReadabilityDetermined` is not invoked from the error path, so the reader-mode toggle does not lose a previously-correct visible state

#### Scenario: A main-frame error still clears the loading spinner
- **WHEN** a main-frame error occurs and the carrier is not yet `isReady`
- **THEN** `onLoadComplete` is invoked so the loading indicator is dismissed, even though no readability result is asserted

#### Scenario: A genuinely broken first-ever page has no toggle, same as before
- **WHEN** a carrier's very first page load encounters a main-frame error before any successful determination has ever been recorded
- **THEN** `cachedIsReaderable` remains `null` (rather than becoming `false`), and the reader-mode toggle stays hidden — behaviorally unchanged from asserting `false` explicitly, since the toggle's visibility gate treats "never determined" and "determined not readerable" the same way

### Requirement: A load-error conclusion is tracked separately from a readability result
`WebViewCarrier` SHALL track, via a `loadFailedWithoutResult` flag distinct from `cachedIsReaderable`, whether the current load attempt already concluded (via `onWebResourceError`) without ever producing a readability result. This flag SHALL be set only inside `onWebResourceError`'s `if (!isReady)` branch, and SHALL be reset to `false` at every point the cache is invalidated (the eager `onUrlChange`-time check, `_onPageFinished`'s top-of-function check, and both of `_onPageFinished`'s genuine-determination points), so a fresh navigation attempt is never left carrying a stale value from a previous one. This flag exists so a caller wanting reader mode can distinguish "still genuinely waiting for a determination" from "no determination is coming for this attempt" without conflating either case with `cachedIsReaderable`'s `true`/`false`/`null` states (which must remain reserved for genuine content-based results, per the requirement above).

#### Scenario: A caller can tell a settled-without-result attempt apart from one still in progress
- **WHEN** a main-frame error occurs and the carrier is not `isReady`
- **THEN** `loadFailedWithoutResult` becomes `true`, distinguishing this state from a genuinely in-flight analysis (where it remains `false`) even though both report `isReady == false` and `cachedIsReaderable == null`

#### Scenario: A fresh navigation attempt always starts with a clean slate
- **WHEN** `loadFailedWithoutResult` is `true` from a previous failed attempt, and the webview then navigates to a different URL, or the same URL reloads and the cache is invalidated for any reason
- **THEN** `loadFailedWithoutResult` is reset to `false`, giving the new attempt a full opportunity to reach a genuine determination

