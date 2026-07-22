# Sibling WebView Preload

## Purpose

Defines correctness requirements for the preload system that simultaneously mounts sibling `DisplayArticle` widgets. Covers panel isolation, lifecycle safety, load-completion signalling, index-range bounds, and ordering of carrier side effects relative to Flutter state updates.

## Requirements

### Requirement: Panel controller is per-article instance
Each `DisplayArticle` widget SHALL own its own `PanelController` instance. Opening or closing the comments panel on one article SHALL NOT affect the sliding panel state of any sibling article that is simultaneously mounted by the preload system.

#### Scenario: Sibling panel isolation
- **WHEN** the user opens the comments panel on article A while article B is preloaded and mounted
- **THEN** article B's sliding panel remains in its prior state (open or closed) and is not driven by article A's panel controller

### Requirement: `setState` is never called on a disposed widget from the readability callback
The `onReadabilityDetermined` callback in `DisplayArticle` SHALL guard the `setState` call with a `mounted` check placed around (not inside) the `setState` invocation. If the widget is unmounted when the callback fires, no state update SHALL occur and no exception SHALL be thrown.

#### Scenario: Widget unmounted before readability determination completes
- **WHEN** the user navigates away from an article before `onReadabilityDetermined` fires
- **THEN** no exception is thrown and no state update is attempted on the disposed widget

### Requirement: `onLoadComplete` fires exactly once per page-load cycle
`WebViewCarrier._onPageFinished` SHALL call `onLoadComplete` at most once per invocation, regardless of the value of `displayReaderMode`. When an early `onLoadComplete` call is made (for `displayReaderMode == false`), the final call at the end of the method SHALL be suppressed.

#### Scenario: Early completion for reader-mode-off articles
- **WHEN** `displayReaderMode == false` and `_onPageFinished` fires
- **THEN** `onLoadComplete` is called exactly once — the loading spinner is dismissed and `_reconcileDisplayState` runs exactly one time

### Requirement: Carrier index range uses consistent bounds
`_ensureCarriersFor` in `ViewArticles` SHALL clamp both `start` and `end` to `[0, articles.length - 1]`. The upper bound for `start` SHALL be `articles.length - 1`, not `articles.length`.

#### Scenario: Clamping at list boundaries
- **WHEN** `current == 0` and `_preloadRange == 1`
- **THEN** `start == 0` and `end == min(1, articles.length - 1)`, with no index exceeding `articles.length - 1`

### Requirement: Carrier lifecycle side effects are not inside `setState`
`_onPageChanged` in `ViewArticles` SHALL call `_ensureCarriersFor` after (not inside) the `setState` callback, so that `WebViewCarrier` creation and disposal do not occur within Flutter's state-update microtask.

#### Scenario: Page change triggers carrier management outside setState
- **WHEN** the user swipes to a new article
- **THEN** `_currentIndex` is updated via `setState` first, and carrier creation/disposal runs after the state update is scheduled

### Requirement: Sibling articles pre-warm their webview controller
The article pager MUST start loading the previous and next sibling articles' webviews concurrently with the current article so that by the time the user swipes, those siblings have already passed `onPageFinished`.

#### Scenario: Three articles in a PageView
- **WHEN** the user opens the swipeable reader at index `i` of an article list of length `>= 3`
- **THEN** webview controllers for indices `i-1`, `i`, and `i+1` are all constructed and requesting URLs before the user finishes reading the current article

#### Scenario: First article with no previous sibling
- **WHEN** the user opens the swipeable reader at index `0`
- **THEN** only the current and next article controllers are pre-warmed; no attempt is made to preload a non-existent previous article

#### Scenario: Last article with no next sibling
- **WHEN** the user opens the swipeable reader at the final index
- **THEN** only the previous and current article controllers are pre-warmed; no attempt is made to preload a non-existent next article

#### Scenario: Standalone single-article view
- **WHEN** `DisplayArticle` is rendered outside the swipeable reader (no siblings)
- **THEN** exactly one webview controller is created and no sibling preloading occurs

### Requirement: Off-screen webview controllers stay alive for reuse
After an article scrolls out of the visible viewport, its `WebViewController` AND any cached reader HTML / readability result MUST remain available for a reuse window so that swiping back to it does not require re-running the parse.

#### Scenario: User swipes forward then back
- **WHEN** the user swipes from article `i` to article `i+1`, waits, then swipes back to `i`
- **THEN** the reader HTML previously rendered for `i` is available immediately and no `isProbablyReaderable`/Readability parse is re-run

#### Scenario: Reader-mode UI syncs from the cached readability result on warm re-mount
- **WHEN** the user swipes back to an article whose carrier is warm and `cachedIsReaderable` is non-null
- **THEN** the widget MUST surface the cached readability result to its parent once (via the `onReadabilityDetermined` callback) so the reader-mode toggle button visibility and auto-activation flow stay in sync without a re-parse

#### Scenario: Reuse window expires
- **WHEN** an article scrolls out of the visible viewport and remains off-screen beyond the reuse window
- **THEN** its webview controller is disposed to reclaim memory

### Requirement: Readability callback fires only after both cached fields are populated
The carrier MUST populate `cachedReaderHtml` (when readerable) and `cachedIsReaderable` BEFORE firing `onReadabilityDetermined`. Otherwise downstream consumers see a half-initialized state and the auto-reader-mode chain can hang in a spinner.

#### Scenario: First-article parse completes for a fresh visit
- **WHEN** the carrier's first `onPageFinished` runs the readability parse and the page is readerable
- **THEN** `cachedReaderHtml` and `cachedIsReaderable` are both set before `onReadabilityDetermined` is fired

#### Scenario: Reader mode activation runs end-to-end on first visit
- **WHEN** a fresh article finishes its readability parse
- **THEN** the reader-mode auto-activation chain (`onReadabilityDetermined` → BLoC → `didUpdateWidget` → `loadReaderHtml` → `ReaderReady` → `_isLoading=false`) completes and the spinner is dismissed

### Requirement: Warm-mount readiness callback defers to post-frame
The webview widget MUST defer any readability-notification callback that triggers `setState` on a parent widget to a post-frame callback so it does not run synchronously from `didChangeDependencies` during the parent's build phase.

#### Scenario: Warm sibling re-mount does not throw setState-during-build
- **WHEN** the widget mounts with an already-ready carrier
- **THEN** `widget.onReadabilityDetermined` is invoked via `WidgetsBinding.addPostFrameCallback`, not synchronously from `didChangeDependencies`

### Requirement: Auto-reader-mode dispatch is idempotent across re-mounts
The `DisplayArticle` widget MUST NOT dispatch `DisplayReaderModeEvent` if the BLoC's current `state.displayReaderMode` is already `true`. The BLoC's `displayReaderMode` updater is a flip-flop, so re-dispatching on every warm re-mount would repeatedly toggle the persisted state off whenever the user goes back and forth between articles.

#### Scenario: Re-mounting an already-activated article keeps reader mode on
- **WHEN** the widget remounts with a warm carrier whose `cachedIsReaderable` is `true` AND the article's persisted `state.displayReaderMode` is already `true`
- **THEN** no `DisplayReaderModeEvent` is dispatched (the `setState` for `_isReaderable` still runs so the toggle button is visible)

### Requirement: Reader HTML renders with mobile-friendly viewport
The rendered reader HTML MUST declare a mobile viewport so that text and images are sized correctly on iOS/Android WebViews without the user seeing a desktop-scaled layout.

#### Scenario: iOS reader view fills the device width
- **WHEN** the reader HTML is loaded into the WebView on iOS Safari/WebKit or Android WebView
- **THEN** the content is sized to the device's width (no desktop-scale shrinking) and user pinch-zoom remains enabled

### Requirement: Pre-warmed sibling transition is near-instant
When the user swipes from the current article to a previously-pre-warmed sibling, the new article MUST display either the reader HTML or the raw webview without a fresh loading spinner, because the load has already completed.

#### Scenario: Swipe to a pre-warmed readerable sibling
- **WHEN** the user swipes from article `i` to article `i+1` where `i+1` was pre-warmed and `isProbablyReaderable` returned true
- **THEN** reader mode renders immediately with no spinner visible

#### Scenario: Swipe to a pre-warmed non-readerable sibling
- **WHEN** the user swipes from article `i` to article `i+1` where `i+1` was pre-warmed and `isProbablyReaderable` returned false
- **THEN** the raw webview is displayed with no spinner visible

### Requirement: Reader mode toggle reuses cached state
When the user toggles reader mode on a previously-visited article whose webview is still warm, the system MUST use the cached `_downloadedHtml` rather than re-running Readability.

#### Scenario: Toggle reader mode off then on for a warm sibling
- **WHEN** the user toggles reader mode off then on for an article whose webview is still alive in the sibling cache
- **THEN** reader HTML is rendered from the cached parse without re-running the Readability JS bundle or `isProbablyReaderable`

### Requirement: Callbacks are silently dropped after carrier disposal
After `WebViewCarrier.dispose()` is called, any in-flight async operations inside the carrier (e.g., `_onPageFinished` suspended at an `await`) SHALL NOT invoke `onReadabilityDetermined`, `onLoadComplete`, `onHtmlReady`, or `onExternalNavigation` — even if those callbacks are still set at the time the `await` resolves. The carrier SHALL maintain an internal `_isDisposed` flag checked after each `await` boundary.

#### Scenario: Carrier disposed mid-extraction
- **WHEN** `_onPageFinished` is suspended at `await _bundleReady` and `dispose()` is called on the carrier before the future resolves
- **THEN** no callback is invoked after `_bundleReady` completes, and no further JS is run on the controller

#### Scenario: Carrier disposed after bundle load but before Readability parse
- **WHEN** `_onPageFinished` has injected the bundle and is about to call `isProbablyReaderable`, but `dispose()` is called between those two `await` points
- **THEN** `isProbablyReaderable` is not called and `onReadabilityDetermined` is not fired

#### Scenario: Normal extraction completes before disposal
- **WHEN** `_onPageFinished` runs to completion and `dispose()` is called afterward
- **THEN** all callbacks have already fired normally and no double-invocation or error occurs
