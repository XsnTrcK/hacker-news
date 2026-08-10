## Purpose

Lets the user choose the app's launcher icon (and Web favicon) from a fixed set of options in Settings, applied at runtime and persisted across restarts.

## Requirements

### Requirement: User can select the app's launcher icon
The system SHALL let the user choose the app's launcher icon from a fixed set of options (`icon`, `crayons`, `lines`) via a control on the Settings page, presented in the same label-left/radio-buttons-right style used by the existing Font Size and Theme Mode settings.

#### Scenario: User selects a different icon
- **WHEN** the user selects an icon option that is not the currently active one
- **THEN** the system SHALL attempt to apply that icon as the app's launcher icon on the current platform

#### Scenario: Selected option reflects the active icon
- **WHEN** the Settings page is displayed
- **THEN** the radio button matching the currently active `AppIcon` SHALL be shown as checked, and the other two SHALL be shown as unchecked

### Requirement: Selected icon is persisted
The system SHALL persist the user's selected icon so it remains active across app restarts.

#### Scenario: App restarts after a successful icon change
- **WHEN** the user has successfully changed the icon and then restarts the app
- **THEN** the previously selected icon SHALL still be reported as the active `AppIcon` value

#### Scenario: No prior selection exists
- **WHEN** the app is launched for the first time with no persisted icon preference
- **THEN** the system SHALL treat `icon` as the active `AppIcon` value

### Requirement: Icon change applies at runtime per platform
The system SHALL apply the selected icon at runtime without requiring an app reinstall, using the mechanism appropriate to the running platform:
- Android: toggling `activity-alias` component enablement so exactly one alias (matching the selected icon) is enabled at a time.
- iOS: invoking `UIApplication.setAlternateIconName` with the icon name matching the selection (or `nil` for the default `icon` selection).
- Web: updating the page's favicon `<link>` element to reference the selected icon's image.

Windows is out of scope for runtime icon switching; the launcher icon on Windows SHALL remain the single build-time icon.

#### Scenario: Icon change on Android
- **WHEN** the user selects an icon on Android
- **THEN** the system SHALL enable the `activity-alias` corresponding to that icon and disable the other icon aliases

#### Scenario: Icon change on iOS
- **WHEN** the user selects an icon on iOS
- **THEN** the system SHALL call `setAlternateIconName` with the value corresponding to that icon, using `nil` when the selection is the default `icon`

#### Scenario: Icon change on Web
- **WHEN** the user selects an icon on Web
- **THEN** the system SHALL update the favicon `<link>` element's href to the selected icon's image without a full page reload

#### Scenario: Icon change on Windows
- **WHEN** the app is running on Windows
- **THEN** the icon selection control's changes SHALL have no effect on the Windows executable's icon

### Requirement: Failed icon change is surfaced without corrupting state
If applying the selected icon at the platform level fails, the system SHALL notify the user and SHALL NOT persist or report the failed selection as active.

#### Scenario: Native icon change call fails
- **WHEN** the platform-level call to apply the selected icon throws or fails
- **THEN** the system SHALL show a toast reading "Could not update icon."
- **AND** the previously active `AppIcon` SHALL remain the persisted and reported value
