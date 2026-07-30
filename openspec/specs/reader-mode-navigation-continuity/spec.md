# reader-mode-navigation-continuity Specification

## Purpose
TBD - created by archiving change reader-mode-cache-invalidation. Update Purpose after archive.
## Requirements
### Requirement: Reader mode is a single sticky toggle, not scoped to a specific URL
The system SHALL treat `item.state.displayReaderMode` as the sole source of truth for reader-mode display, regardless of which page within the webview is currently shown. Toggling reader mode — whether while viewing the article's own URL or a page reached via an in-content link — SHALL dispatch `DisplayReaderModeEvent` against the same persisted value. There SHALL NOT be a separate, non-persisted "local" toggle state for pages reached via navigation.

#### Scenario: Toggling reader mode on a linked-to page persists the same as toggling on the original article
- **WHEN** the user has navigated to a page reached via a link and taps the reader-mode toggle button
- **THEN** `DisplayReaderModeEvent(item)` is dispatched exactly as it would be if the toggle were tapped while viewing the article's own URL, updating the same persisted `displayReaderMode` value

#### Scenario: Toggle button reads the same persisted value everywhere
- **WHEN** the reader-mode toggle button is rendered, regardless of which page is currently displayed in the webview
- **THEN** its icon state reflects `item.state.displayReaderMode ?? false` directly, with no branching based on which page is shown

### Requirement: Reader mode continues to apply automatically across in-content navigation
When reader mode is currently on (`item.state.displayReaderMode == true`) and the user navigates to a different page via a link, the system SHALL automatically attempt reader mode for the newly-loaded page once its own readability determination completes, without requiring the user to toggle it again.

#### Scenario: Reader mode carries forward to a linked-to readerable page
- **WHEN** reader mode is on, the user taps a link, and the newly-loaded page is determined to be readerable
- **THEN** the newly-loaded page is displayed in reader mode automatically, without any additional user action

#### Scenario: Reader mode does not apply to a linked-to non-readerable page
- **WHEN** reader mode is on, the user taps a link, and the newly-loaded page is determined not to be readerable
- **THEN** the newly-loaded page is displayed live (reader mode cannot apply); the reader-mode toggle button's visibility is unaffected by this page's own result (see "Toggle visibility is decided once, by the original article's own URL")

#### Scenario: Reader mode being off also carries forward
- **WHEN** reader mode is off and the user taps a link to a readerable page
- **THEN** the newly-loaded page is displayed live, not automatically switched into reader mode — the off state continues to apply until the user explicitly toggles it back on

### Requirement: Wanting reader mode while analysis is in flight shows a loading indicator until determined
Whenever reader mode is wanted for the currently-displayed page but that page's own readability determination has not yet completed, the system SHALL show a loading indicator for the duration of the determination and SHALL NOT silently do nothing while waiting. This applies both when reader mode is already on and the user navigates to a new page via a link, and when the user toggles reader mode on for a page whose analysis is still in progress (e.g. immediately after navigating to it).

#### Scenario: No flash of the live page before reader mode activates
- **WHEN** reader mode is on and the user taps a link to a readerable page
- **THEN** a loading indicator is shown continuously from the moment of navigation until reader-mode content is rendered — the live raw page is never visible in between

#### Scenario: Loading indicator resolves to the live page when not readerable
- **WHEN** reader mode is on and the user taps a link to a page that turns out not to be readerable
- **THEN** the loading indicator is shown until that determination completes, then the live page is revealed

#### Scenario: No blocking indicator when reader mode is off
- **WHEN** reader mode is off and the user taps a link
- **THEN** the page loads and displays live without waiting for a readability determination, matching the existing behavior for reader-mode-off pages

#### Scenario: Toggling reader mode on before the current page's analysis finishes shows the indicator immediately
- **WHEN** the user is on a page whose own readability analysis has not yet completed and taps the reader-mode toggle to turn it on
- **THEN** a loading indicator is shown immediately, rather than nothing happening until the analysis completes some time later

#### Scenario: Toggling reader mode on after analysis has already completed is instant
- **WHEN** the user is on a page whose own readability analysis has already completed (`cachedReaderHtml` already populated) and taps the reader-mode toggle to turn it on
- **THEN** reader-mode content is shown immediately, with no loading indicator needed

#### Scenario: A load failure without a result triggers one retry rather than giving up
- **WHEN** the user wants reader mode for a page whose load attempt already concluded via a main-frame error without ever producing a readability result (`loadFailedWithoutResult` is `true`)
- **THEN** the system retries once by forcing a fresh reload of that page (`loadOriginal()`), showing a loading indicator while the retry is in flight, rather than leaving reader mode permanently unable to activate for that page

#### Scenario: The indicator does not spin forever if the retry also fails without a result
- **WHEN** the one-shot retry described above itself concludes via a main-frame error without ever producing a readability result
- **THEN** no further retry is attempted and no loading indicator is shown for that attempt — reader mode simply does not activate for that page, rather than looping or showing an indicator with no corresponding completion event to ever clear it

#### Scenario: A fresh navigation gets its own retry opportunity
- **WHEN** a page has already exhausted its one retry after a load failure, and the user then navigates to a different page (or the same page reloads via a genuine navigation, not the retry itself)
- **THEN** the retry-once guard resets, so the new navigation attempt is not penalized by the previous attempt's exhausted retry

### Requirement: Toggle visibility is decided once, by the original article's own URL
The reader-mode toggle button's visibility SHALL be determined solely by the readability result of the article's own URL and SHALL NOT change based on the readability of any page subsequently reached via an in-content link. `WebViewCarrier` SHALL only invoke `onReadabilityDetermined` for a determination whose URL matches the carrier's own `resolvedUrl` (fragment-stripped) — determinations for any other URL are recorded internally (`cachedReaderHtml`/`cachedIsReaderable`/`extractedForUrl`, still driving reader-mode content behavior per the requirements above) but are not reported through this callback. This gating SHALL be keyed on the carrier's own URL identity, not on call order, so that visibility remains correct even if the consuming widget's state outlives a single carrier instance (e.g. a sibling-preload carrier disposed and recreated after its reuse window expires, per the `sibling-webview-preload` capability).

#### Scenario: Original article is not readerable — toggle never appears
- **WHEN** the article's own URL is determined not to be readerable, and the user subsequently navigates to a linked-to page that IS readerable
- **THEN** the reader-mode toggle button remains hidden — the linked page's readability does not make it appear

#### Scenario: Original article is readerable — toggle stays visible regardless of linked pages
- **WHEN** the article's own URL is determined to be readerable (button visible), and the user subsequently navigates to a linked-to page that is NOT readerable
- **THEN** the reader-mode toggle button remains visible; the linked page simply displays live since there's no reader content for it

#### Scenario: Only determinations for the original URL affect visibility
- **WHEN** `onReadabilityDetermined` fires more than once during a viewing session (once for the original URL, then again for one or more linked-to pages)
- **THEN** only the call whose URL matches the carrier's own `resolvedUrl` updates whether the toggle button is shown; calls for any other URL affect reader-mode content behavior (per the requirements above) but not toggle visibility

#### Scenario: Visibility recovers correctly after a carrier is disposed and recreated
- **WHEN** a sibling-preload carrier is disposed after its reuse window expires and a fresh `WebViewCarrier` is later constructed for the same article (the consuming widget's own state having persisted across this swap)
- **THEN** the new carrier's own determination for its `resolvedUrl` is reported through `onReadabilityDetermined` normally — visibility is not stuck on a stale result from the previous carrier instance

