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
The system SHALL persist the user's selected icon so it remains active across app restarts. On platforms where applying the icon may itself terminate the app process (see "Icon change applies at runtime per platform"), the system SHALL durably persist the selection before invoking the platform-level call that applies it, so the selection is not lost if the process is terminated before that call returns.

#### Scenario: App restarts after a successful icon change
- **WHEN** the user has successfully changed the icon and then restarts the app
- **THEN** the previously selected icon SHALL still be reported as the active `AppIcon` value

#### Scenario: Platform-level apply call terminates the process
- **WHEN** the platform-level call to apply a selected icon causes the app process to be terminated before that call returns a result
- **THEN** the selection SHALL already be durably persisted, so the next launch reports the newly selected icon as active, not the previous one

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

### Requirement: Exactly one launcher entry point is presented
The system SHALL ensure exactly one component (an activity, or an activity-alias on Android) declares itself as the app's launcher entry point at any time, regardless of which icon is currently selected.

#### Scenario: Base activity is never independently launchable on Android
- **WHEN** the app is installed on Android
- **THEN** only the activity-alias corresponding to the currently active icon SHALL declare a launcher intent-filter, and the underlying target activity SHALL NOT independently declare one

#### Scenario: Home screen shows a single icon
- **WHEN** the app is installed or updated on Android
- **THEN** the device home screen/launcher SHALL show exactly one icon for the app, matching the currently active `AppIcon`

### Requirement: Resyncing the active icon does not restart the app
The system SHALL treat reapplying the already-active icon (e.g. a startup resync intended to correct drift between the persisted preference and platform state) as a no-op at the platform level, without restarting or terminating the app process.

#### Scenario: Startup resync matches current platform state
- **WHEN** the app starts and the persisted `AppIcon` selection already matches the active platform-level icon state
- **THEN** the system SHALL make no platform-level change and SHALL NOT restart or terminate the app process

#### Scenario: Startup resync detects drift
- **WHEN** the app starts and the persisted `AppIcon` selection does not match the active platform-level icon state
- **THEN** the system SHALL apply the persisted selection at the platform level, which MAY restart or terminate the app process per the platform's normal icon-change mechanism
