## ADDED Requirements

### Requirement: Comment bodies are never persisted
The system SHALL always fetch comment content (text, kids, parent, deleted, dead) from the network and SHALL NOT persist comment content to the `"comments"` Hive box under any circumstance, including for comments belonging to a bookmarked article.

#### Scenario: Viewing a comment thread does not cache comment content
- **WHEN** the user opens a comment thread and comments are fetched from the network
- **THEN** no comment text, kids, parent, deleted, or dead field is written to the `"comments"` Hive box

#### Scenario: Revisiting a thread re-fetches comment content
- **WHEN** the user navigates away from a comment thread and later reopens it
- **THEN** comment content is fetched from the network again rather than read from disk

#### Scenario: Bookmarking an article does not cache its comment tree
- **WHEN** the user bookmarks an article that has comments
- **THEN** no comment content for that article's comment tree is written to the `"comments"` Hive box as a result of the bookmark action

### Requirement: Presence-only persistence for manually collapsed comments
The system SHALL persist a record for a comment id in the `"comments"` Hive box if and only if the user has manually collapsed that comment. The stored record SHALL carry no payload beyond the key's presence — the existence of the key indicates collapsed, and its absence indicates expanded (the default state).

#### Scenario: Manually collapsing a comment persists a marker
- **WHEN** the user manually collapses a comment
- **THEN** a presence marker for that comment's id is written to the `"comments"` box

#### Scenario: Re-expanding a comment removes its marker
- **WHEN** the user manually re-expands a comment that was previously collapsed
- **THEN** the presence marker for that comment's id is deleted from the `"comments"` box, not overwritten

#### Scenario: Comments never interacted with have no record
- **WHEN** a comment is rendered and the user never collapses it
- **THEN** no record for that comment's id exists in the `"comments"` box

#### Scenario: Collapsed state is restored on revisit
- **WHEN** the user previously collapsed a comment, navigates away, and reopens the same thread
- **THEN** that comment renders collapsed, using the presence marker to override the default expanded state

### Requirement: One-time migration clears the legacy comment cache
On first launch after this change is deployed, the system SHALL delete all pre-existing entries in the `"comments"` Hive box rather than attempting to recover prior collapse state from cached comment content. This migration SHALL run at most once per install.

#### Scenario: Legacy cached comment content is removed on upgrade
- **WHEN** the app upgrades from a version that cached full comment content
- **THEN** after migration, the `"comments"` box contains no entries carried over from the previous version

#### Scenario: Previously collapsed comments default to expanded after migration
- **WHEN** a comment was manually collapsed under the previous version and the app upgrades
- **THEN** that comment renders expanded (the default state) after migration, since its prior collapse state is not recoverable
