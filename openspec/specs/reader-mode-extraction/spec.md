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
When `WebViewCarrier.loadOriginal()` is called to reload or re-navigate the underlying page, the carrier SHALL reset `cachedIsReaderable` and `cachedReaderHtml` to `null` so that a subsequent `onPageFinished` re-attempts Readability analysis instead of being short-circuited by a prior failed attempt.

#### Scenario: Retry after a failed first pass
- **WHEN** a page's first `onPageFinished` analysis concludes `cachedIsReaderable == false` (e.g., due to a premature check on unhydrated SPA content), and the page later reloads via `loadOriginal()`
- **THEN** the next `onPageFinished` for that navigation re-runs `isProbablyReaderable` and, if applicable, the full Readability parse — it is not skipped by the earlier `false` result

#### Scenario: Successful extraction is not needlessly re-run
- **WHEN** `cachedReaderHtml` is already populated from a successful extraction and no `loadOriginal()` call has occurred since
- **THEN** subsequent `onPageFinished` invocations continue to short-circuit as before, avoiding redundant extraction work
