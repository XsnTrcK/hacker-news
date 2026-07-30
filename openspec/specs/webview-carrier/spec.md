# WebView Carrier

## Purpose

Defines the lifecycle and API contract for `WebViewCarrier` — the object that holds a preloaded `WebViewController` and bridges it into a `MobileWebView` widget. Covers public field naming conventions, ownership-based teardown, and the correct Flutter lifecycle hook for reading inherited widget state.

## Requirements

### Requirement: WebView widget uses consistent public field naming
`WebView` SHALL expose its reader mode flag as `displayReaderMode` (public, no leading underscore), matching the convention used by `MobileWebView`.

#### Scenario: Field name matches wrapped widget
- **WHEN** `WebView` is constructed with a reader mode value
- **THEN** the field is accessible and named `displayReaderMode`, consistent with `MobileWebView.displayReaderMode`

---

### Requirement: WebViewCarrier is detached or disposed exactly once per MobileWebView lifecycle
`_MobileWebViewState.dispose()` SHALL call either `detach()` or `dispose()` on the carrier — never both. When the state owns the carrier (`_ownsCarrier == true`), it SHALL call `dispose()` only. When it does not own the carrier, it SHALL call `detach()` only.

#### Scenario: Owned carrier is fully torn down once
- **WHEN** a `MobileWebView` that created its own `WebViewCarrier` is disposed
- **THEN** `WebViewCarrier.dispose()` is called exactly once and `detach()` is not called separately

#### Scenario: Non-owned carrier is detached but not disposed
- **WHEN** a `MobileWebView` using an externally-provided `WebViewCarrier` is disposed
- **THEN** `WebViewCarrier.detach()` is called and `dispose()` is not called

---

### Requirement: `_readerViewStyle` is set only in `didChangeDependencies`
`_MobileWebViewState.build()` SHALL NOT assign to `_readerViewStyle`. The assignment SHALL exist only in `didChangeDependencies()`, which is the correct Flutter lifecycle hook for reading inherited widgets.

#### Scenario: Reader style is current before first build
- **WHEN** `MobileWebView` mounts for the first time
- **THEN** `_readerViewStyle` is populated by `didChangeDependencies()` before `build()` runs, with no assignment in `build()`

#### Scenario: Reader style updates on theme change
- **WHEN** the app theme changes while `MobileWebView` is mounted
- **THEN** `didChangeDependencies()` fires, updates `_readerViewStyle`, and the next `build()` uses the new value without needing its own assignment

---

### Requirement: `_carrier` reference is re-synchronized when `widget.carrier` identity changes
`_MobileWebViewState.didUpdateWidget` SHALL compare `oldWidget.carrier` and `widget.carrier` by identity. When they differ, the state SHALL detach or dispose the previous carrier's wiring as appropriate for its prior ownership, adopt the new carrier (rewiring its callbacks and re-running `_reconcileDisplayState`), and update the ownership flag (`_ownsCarrier`) to reflect whether the new carrier is externally supplied.

#### Scenario: Parent supplies a new carrier for the same widget slot
- **WHEN** `ViewArticles` evicts and later recreates the `WebViewCarrier` for a given page index, and Flutter reuses the existing `MobileWebView` `State` for that slot (no explicit key)
- **THEN** `didUpdateWidget` detects `oldWidget.carrier != widget.carrier`, rewires all carrier callbacks onto the new carrier, and subsequent interactions (`canGoBack`, loading state, reader-mode toggling) reflect the new carrier — not the disposed one

#### Scenario: Carrier identity is unchanged across a rebuild
- **WHEN** `MobileWebView` rebuilds with the same `widget.carrier` instance as before
- **THEN** no re-wiring occurs and existing carrier callbacks remain attached

---

### Requirement: Reader-HTML load has a fallback completion signal
When `MobileWebView` transitions into reader mode via `_reconcileDisplayState`, the loading state (`_isLoading`/`_awaitingReaderHtml`) SHALL be cleared by a fallback timeout if the `ReaderReady` JavaScript channel message does not arrive within a bounded duration, in addition to the existing message-driven completion path.

#### Scenario: ReaderReady message never arrives
- **WHEN** reader HTML is loaded via `loadReaderHtml` and the trailing `ReaderReady` postMessage script does not execute (e.g., malformed content, WebView engine quirk) within the fallback duration
- **THEN** the loading spinner is dismissed by the fallback timeout instead of remaining visible indefinitely

#### Scenario: ReaderReady message arrives normally
- **WHEN** the `ReaderReady` message fires before the fallback timeout elapses
- **THEN** the message-driven path clears the loading state as before, and the fallback timeout is cancelled with no visible effect
