## Purpose

Bounds on-disk storage for fetched articles by actual user interaction rather than browsing volume, by persisting only a lean `{id, displayReaderMode, bookmarked}` record for articles whose reader-mode or bookmark state has been explicitly touched, and by migrating pre-existing full-content records to this shape on first launch.

## Requirements

### Requirement: Lean-by-default article persistence
The system SHALL NOT persist an article's title, url, score, text, kids, or descendants to the `"news"` Hive box. The system SHALL write a record for an article to the `"news"` box only when that article's `displayReaderMode` has been explicitly set (non-null) or its `savedForReadLater` (bookmarked) flag has been explicitly toggled by the user. When written, the record SHALL contain only `{id, displayReaderMode, bookmarked}`.

#### Scenario: Article fetched for a list view is not persisted
- **WHEN** an article is fetched to render a news list (top/new/best/ask/show/job) and the user has never toggled its reader mode or bookmark state
- **THEN** no record for that article's id exists in the `"news"` Hive box

#### Scenario: Reader mode toggle persists a lean record
- **WHEN** the user toggles reader mode on an article that has never been bookmarked
- **THEN** a record `{id, displayReaderMode, bookmarked: null}` is written to the `"news"` box, containing no title, url, score, text, kids, or descendants

#### Scenario: Bookmark toggle persists a lean record in the news box
- **WHEN** the user bookmarks an article that has never had its reader mode toggled
- **THEN** a record `{id, displayReaderMode: null, bookmarked: true}` is written to the `"news"` box, containing no title, url, score, text, kids, or descendants

### Requirement: hasBeenRead is removed
The system SHALL NOT track or persist a `hasBeenRead` flag on any article. `ItemState`, the `ItemUpdater` mixin, and `Store` SHALL NOT expose a `hasBeenRead` field or a `markHasBeenRead` method.

#### Scenario: Opening an article does not write a hasBeenRead flag
- **WHEN** the user opens any article
- **THEN** no `hasBeenRead` value is read, written, or referenced anywhere in the article's stored state

### Requirement: One-time migration preserves existing reader-mode toggles
On first launch after this change is deployed, the system SHALL scan any pre-existing full-content entries in the `"news"` Hive box exactly once and, for each article whose previously-stored `displayReaderMode` was non-null, write the equivalent lean record. All other pre-existing full-content entries SHALL be discarded. This migration SHALL run at most once per install.

#### Scenario: Pre-existing reader-mode toggle survives migration
- **WHEN** the app upgrades from a version that stored full article content and an article had a non-null `displayReaderMode` in the old record
- **THEN** after migration, a lean record for that article's id exists in the `"news"` box with the same `displayReaderMode` value

#### Scenario: Pre-existing untouched article does not survive migration
- **WHEN** the app upgrades and an old full-content record exists for an article whose `displayReaderMode` was null and which was never bookmarked
- **THEN** after migration, no record for that article's id exists in the `"news"` box

#### Scenario: Migration does not re-run on subsequent launches
- **WHEN** the app is launched again after the migration has already completed once
- **THEN** the `"news"` box scan is not repeated
