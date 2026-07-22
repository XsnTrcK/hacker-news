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
