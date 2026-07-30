## Purpose

Automatically activate reader mode for any article page where `isProbablyReaderable` returns true, removing the need for manual user interaction. While the WebView loads in the background, a native Flutter loading spinner is shown; once readability is determined the spinner is dismissed and either reader HTML or the normal webview is revealed. The reader mode toggle button remains fully functional so users can still override the auto-activated state.

## Requirements

### Requirement: Loading spinner shown on article open
The system SHALL display a native loading spinner overlaid on a background matching `scaffoldBackgroundColor` from the moment an article opens until content is definitively ready (reader HTML rendered or normal webview confirmed non-readerable).

#### Scenario: Spinner appears immediately on article open
- **WHEN** the user navigates to any article (HN story or RSS item)
- **THEN** a `ProgressBar` spinner is shown centered on screen over a blank background

#### Scenario: Spinner hides after non-readerable page finishes loading
- **WHEN** `onPageFinished` fires and `isProbablyReaderable` returns false
- **THEN** the spinner is removed and the normal webview is revealed

#### Scenario: Spinner hides after reader HTML is committed
- **WHEN** `isProbablyReaderable` returns true and the reader HTML has finished loading (second `onPageFinished`)
- **THEN** the spinner is removed and the reader view is revealed

### Requirement: Reader mode auto-activates on readerable pages
The system SHALL automatically activate reader mode for any article page where `isProbablyReaderable` returns true, without requiring user interaction. When the webview being activated is a pre-warmed sibling controller whose `isProbablyReaderable` result and reader HTML were already computed, the system SHALL reuse those cached results instead of re-running the parse.

#### Scenario: Reader mode activates automatically
- **WHEN** `onPageFinished` fires and `isProbablyReaderable` returns true
- **THEN** `DisplayReaderModeEvent` is dispatched via `ItemBloc` and reader HTML is loaded

#### Scenario: Reader mode activates from cached sibling state
- **WHEN** the user swipes to an article whose sibling pre-warm completed and `isProbablyReaderable` already returned true
- **THEN** reader mode is activated without re-running the Readability JS bundle, `isProbablyReaderable`, or Readability parse

#### Scenario: Reader mode button reflects auto-activated state
- **WHEN** reader mode auto-activates
- **THEN** the reader mode button icon changes to `FluentIcons.reading_mode_solid`

#### Scenario: Non-readerable pages do not auto-activate reader mode
- **WHEN** `onPageFinished` fires and `isProbablyReaderable` returns false
- **THEN** reader mode is NOT activated and the normal webview remains visible

### Requirement: Manual reader mode toggle remains functional
The system SHALL allow users to manually toggle reader mode off or on after auto-activation.

#### Scenario: User disables auto-activated reader mode
- **WHEN** reader mode was auto-activated and the user taps the reader mode button
- **THEN** the normal webview is restored and the button icon changes to `FluentIcons.reading_mode`

#### Scenario: User re-enables reader mode after disabling
- **WHEN** the user taps the reader mode button after manually disabling it
- **THEN** reader HTML is reloaded and reader mode is restored

### Requirement: Auto-activation applies to both HN and RSS articles
The system SHALL apply auto-reader-mode behavior uniformly to all article types.

#### Scenario: RSS article auto-activates reader mode
- **WHEN** the user opens an RSS story article and `isProbablyReaderable` returns true
- **THEN** reader mode auto-activates using the same flow as HN articles

### Requirement: Reader-mode toggle visibility does not depend on unsupported platforms
The reader-mode toggle button's visibility SHALL NOT silently remain hidden on platforms whose WebView implementation does not report readability. Each platform-specific WebView implementation SHALL either invoke `onReadabilityDetermined` when it can determine readability, or the toggle visibility logic SHALL account for platforms where that determination is not supported.

#### Scenario: Windows WebView readability support
- **WHEN** the app runs on Windows, where `WindowsWebView` does not perform Readability analysis
- **THEN** the reader-mode toggle button's visibility SHALL be governed by an explicit, documented platform capability check rather than silently defaulting to hidden because `onReadabilityDetermined` is never called

#### Scenario: Supported platform (iOS/Android) behavior is unchanged
- **WHEN** the app runs on iOS or Android
- **THEN** `onReadabilityDetermined` fires as before and the toggle button visibility reflects the live readability result
