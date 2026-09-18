# Adaptive Navigation Shell Specification

## Purpose

Gives the app's top-level navigation (Menu/News/Search destinations and the HN/RSS category filters) a width-aware layout so tablets and unfolded foldables get a persistent side rail instead of a phone-style swipe-and-bottom-bar shell.

## Requirements

### Requirement: Width-based layout mode
The system SHALL determine a navigation layout mode — compact or wide — from the available width, independent of any fold/hinge state, and SHALL re-evaluate this mode whenever the available width changes (e.g. window resize, orientation change).

#### Scenario: Narrow window uses compact mode
- **WHEN** the available width is below the navigation breakpoint
- **THEN** the system uses the compact navigation layout

#### Scenario: Wide window uses wide mode
- **WHEN** the available width is at or above the navigation breakpoint
- **THEN** the system uses the wide navigation layout

#### Scenario: Resizing across the breakpoint switches layout live
- **WHEN** a window already displaying one layout mode is resized past the breakpoint in either direction
- **THEN** the system switches to the other layout mode without requiring navigation away and back

### Requirement: Compact layout preserves existing swipe navigation
In compact mode, the system SHALL present Menu, News, and Search as swipeable pages with a bottom navigation bar for feed mode, matching current behavior.

#### Scenario: Swiping between destinations in compact mode
- **WHEN** the app is in compact mode
- **THEN** the user can swipe horizontally between the Menu, News, and Search pages

### Requirement: Wide layout uses a persistent navigation rail
In wide mode, the system SHALL present Menu, News, and Search destinations, and the feed-mode selection (All/HN/RSS), as a persistent side navigation rail rather than a bottom navigation bar, and SHALL NOT enable horizontal swipe navigation between these destinations.

#### Scenario: Selecting a destination in wide mode
- **WHEN** the app is in wide mode and the user selects a destination on the side rail
- **THEN** the system displays that destination's content without a swipe gesture being required or available for switching top-level destinations

#### Scenario: Swipe gesture is unavailable in wide mode
- **WHEN** the app is in wide mode
- **THEN** a horizontal swipe over the main content area does not switch between Menu, News, and Search

### Requirement: Category filters available in both layout modes
The HN type filter (Top/New/Best/Ask/Show/Jobs) and the RSS feed filter SHALL present the same set of options and selection behavior in both compact and wide mode. In compact mode this is a horizontal scrollable chip row. In wide mode it is a floating action button rather than a panel next to the rail: a fanned-out set of buttons for the HN filter (a small, fixed option count), and a scrollable dropdown menu anchored to a FAB for the RSS filter (an unbounded, user-added option count).

#### Scenario: Selecting an HN category in wide mode updates results
- **WHEN** the app is in wide mode showing the Hacker News feed and the user selects a different HN category from the filter FAB
- **THEN** the news list updates to that category, identically to selecting it in compact mode

#### Scenario: RSS filter only shown when RSS feeds exist
- **WHEN** no RSS feeds are configured
- **THEN** the RSS filter is not shown, in either compact or wide mode

#### Scenario: RSS filter FAB scrolls rather than overflowing for many feeds
- **WHEN** the app is in wide mode showing the RSS feed and the number of configured feeds exceeds what fits on screen
- **THEN** the RSS filter's dropdown scrolls to reveal the remaining feeds instead of extending past the screen edge

### Requirement: Menu destinations reachable in both layout modes
Saved Articles, RSS Feeds, and Settings SHALL be reachable as navigation destinations in both compact mode (via the swipeable Menu page) and wide mode (via the side rail), leading to the same underlying screens.

#### Scenario: Opening Settings in wide mode
- **WHEN** the app is in wide mode and the user selects Settings from the side rail
- **THEN** the Settings screen is displayed

### Requirement: Search reachable in both layout modes
Search SHALL be reachable as a navigation destination in both compact mode (swipeable page) and wide mode (side rail), preserving query text and results when switching to and from Search within the same layout mode.

#### Scenario: Query persists across destination switches in wide mode
- **WHEN** the app is in wide mode, the user has entered a search query with results, and the user navigates to another destination and back to Search
- **THEN** the query text and results are still displayed

### Requirement: Back navigation steps through wide-mode destination history
In wide mode, the system SHALL maintain a history of previously-shown top-level destinations (feed mode, Search, Menu destinations) and SHALL make the system back gesture/button step back through that history one destination at a time, rather than exiting the app, whenever history is non-empty.

#### Scenario: Back button returns to the previous wide-mode destination
- **WHEN** the app is in wide mode, the user has navigated from the News feed to Settings via the rail, and the user triggers the system back gesture/button
- **THEN** the app returns to the News feed instead of exiting

#### Scenario: Back exits normally when there is no wide-mode history
- **WHEN** the app is in wide mode showing its initial destination with no prior navigation in the session
- **THEN** the system back gesture/button behaves normally (does not attempt to step back through wide-mode destinations)
