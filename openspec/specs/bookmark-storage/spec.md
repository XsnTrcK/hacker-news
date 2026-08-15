## Purpose

Keeps a durable, full-content copy of every bookmarked article in a dedicated Hive box so the Saved-For-Later list loads instantly and offline, ordered by bookmark recency, without depending on the article's source (HN or RSS) still having the content available.

## Requirements

### Requirement: Full-content persistence for bookmarked articles
The system SHALL persist the complete item content (equivalent to `Item.toMap()`) for every bookmarked article in a dedicated `"bookmarks"` Hive box, keyed by article id, alongside a `bookmarkedAt` timestamp recorded at the time of bookmarking. This is the only case in which full article content is written to disk.

#### Scenario: Bookmarking an article stores full content
- **WHEN** the user bookmarks an article
- **THEN** a record containing the full item content and a `bookmarkedAt` timestamp is written to the `"bookmarks"` box under that article's id

#### Scenario: Unbookmarking an article removes it from the bookmarks box
- **WHEN** the user removes a bookmark from a previously-bookmarked article
- **THEN** the corresponding record is deleted from the `"bookmarks"` box

#### Scenario: Bookmarked RSS article content survives feed rotation
- **WHEN** an RSS article is bookmarked and its entry later ages out of the source feed's current window
- **THEN** the article's title, url, and feed name remain available from the `"bookmarks"` box without depending on the source feed still containing that entry

### Requirement: Saved-For-Later list ordered by bookmark recency
The system SHALL render the Saved-For-Later list ordered by `bookmarkedAt` descending (most recently bookmarked first), derived by loading all `"bookmarks"` box entries and sorting them in memory. The system SHALL NOT rely on the Hive box's native key iteration order to determine this ordering.

#### Scenario: Most recently bookmarked article appears first
- **WHEN** the user bookmarks article A, then later bookmarks article B
- **THEN** the Saved-For-Later list shows article B before article A

#### Scenario: Saved-For-Later list loads without a network request
- **WHEN** the user opens the Saved-For-Later tab
- **THEN** all bookmarked articles render using only data already present in the `"bookmarks"` box, without fetching each article's metadata from the network

### Requirement: One-time migration preserves existing bookmarks and their order
On first launch after this change is deployed, the system SHALL read the pre-existing ordered bookmark id list and, for each id, migrate its full cached content into the new `"bookmarks"` box with a synthetic `bookmarkedAt` value that preserves the original relative ordering. This migration SHALL run at most once per install.

#### Scenario: Existing bookmark order is preserved after migration
- **WHEN** the app upgrades from a version using the old ordered bookmark id list, where article X was bookmarked before article Y
- **THEN** after migration, the Saved-For-Later list still shows article Y before article X

#### Scenario: Old bookmark index is removed after migration
- **WHEN** migration completes
- **THEN** the old ordered bookmark id list is no longer stored in the `"news"` box
