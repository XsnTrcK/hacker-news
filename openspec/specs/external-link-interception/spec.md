# Spec: External Link Interception

## Purpose

When a WebView navigates to a URL with a non-http(s) scheme (e.g., deep links, custom app schemes), the app intercepts the navigation, checks whether the platform has an installed handler, prompts the user for confirmation, and delegates the launch to the OS — rather than letting the WebView attempt and fail to load the URL.

## Requirements

### Requirement: WebView intercepts non-http(s) navigations
The WebView SHALL intercept all navigation requests whose URL scheme is not `http` or `https` and prevent the WebView from attempting to load them.

#### Scenario: Custom scheme navigation is blocked
- **WHEN** the WebView attempts to navigate to a URL with a non-http(s) scheme (e.g., `x-safari-https://`)
- **THEN** the WebView returns `NavigationDecision.prevent`, the navigation is cancelled, and the WebView remains on the current page

#### Scenario: Standard http navigation is not intercepted
- **WHEN** the WebView navigates to a URL with scheme `http` or `https`
- **THEN** the WebView returns `NavigationDecision.navigate` and loads the page normally

### Requirement: App checks platform handler availability before prompting
Before showing any dialog, the app SHALL query the platform to determine whether an installed app can handle the intercepted URL scheme.

#### Scenario: Android detects a handler
- **WHEN** an Android device intercepts a non-http(s) URL
- **THEN** the app calls `canLaunchUrl(uri)` via `url_launcher`; if it returns `true`, a confirmation dialog is shown

#### Scenario: Android finds no handler
- **WHEN** an Android device intercepts a non-http(s) URL and `canLaunchUrl(uri)` returns `false`
- **THEN** no dialog is shown and the WebView silently remains on the current page

#### Scenario: iOS proceeds optimistically when canLaunchUrl is inconclusive
- **WHEN** an iOS device intercepts a non-http(s) URL and `canLaunchUrl(uri)` returns `false` (due to `LSApplicationQueriesSchemes` not declaring the scheme)
- **THEN** the app still shows the confirmation dialog, because `launchUrl` may succeed even without pre-declaration

#### Scenario: Guard condition maps unambiguously to platform rule
- **WHEN** the platform availability check completes
- **THEN** the guard reads `if (!canLaunch && Platform.isAndroid) return;` — returning early only on Android with no registered handler, and always proceeding to the dialog on iOS

### Requirement: User is presented with a confirmation dialog before external launch
When the platform check indicates a handler may be available, the app SHALL display a generic confirmation dialog asking the user whether to open the link in an external app.

#### Scenario: Dialog shown with Open and Cancel actions
- **WHEN** the platform indicates a handler exists (or iOS optimistic path applies)
- **THEN** a dialog appears with the message "This link wants to open in an external app." and two actions: "Cancel" and "Open"

#### Scenario: User cancels the dialog
- **WHEN** the user taps "Cancel" in the confirmation dialog
- **THEN** the dialog is dismissed and the WebView remains on the current page with no external app launched

### Requirement: Confirmed external navigation is delegated to the OS
When the user confirms, the app SHALL call `launchUrl` in external application mode and handle launch failures gracefully.

#### Scenario: Successful external launch
- **WHEN** the user taps "Open" and `launchUrl(uri, mode: LaunchMode.externalApplication)` succeeds
- **THEN** the OS opens the URL in the appropriate native app; the WebView is unaffected

#### Scenario: External launch fails
- **WHEN** the user taps "Open" but `launchUrl` throws or returns `false`
- **THEN** a brief error message is surfaced to the user (e.g., snackbar/InfoBar) and the WebView remains on the current page
