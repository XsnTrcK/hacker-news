## ADDED Requirements

### Requirement: Single-request comment tree fetch
When a user opens a story's comments, the system SHALL retrieve the entire comment tree for that story in a single upstream request, rather than issuing one request per comment.

#### Scenario: Opening a story with many comments
- **WHEN** the user opens a story that has comments
- **THEN** the system issues exactly one upstream request to load the full comment tree for that story

### Requirement: Comment tree caching is preserved
Comments fetched from the upstream source SHALL be cached locally using the same storage format used today, so existing cached comments remain valid and the comment detail view (`getComment`) continues to work for any previously or newly fetched comment.

#### Scenario: Fetching a story's comments populates the local cache
- **WHEN** a story's comment tree is fetched
- **THEN** every comment in the tree is individually retrievable afterward without an additional upstream request

### Requirement: Full re-fetch on each open
Each time a user opens a story's comments, the system SHALL fetch the full current comment tree rather than relying solely on previously cached comments, so newly posted comments are reflected.

#### Scenario: Revisiting a story after new comments were posted
- **WHEN** the user reopens a story whose comment tree previously had no cached comments below some node, and new comments have since been posted
- **THEN** the newly posted comments are present after the fetch

### Requirement: Dead and deleted comments are omitted
The system SHALL NOT display a placeholder for dead or deleted comments; such comments SHALL simply be absent from the loaded comment tree.

#### Scenario: A thread contains a comment marked dead or deleted upstream
- **WHEN** a story's comment tree includes a comment that Hacker News has marked dead or deleted
- **THEN** that comment does not appear in the loaded tree, and no placeholder is shown in its place

### Requirement: Comment fetch failure handling
If the comment tree cannot be retrieved, the system SHALL surface a failure state for that story's comments without affecting the story list or other stories' cached comments.

#### Scenario: Upstream request fails
- **WHEN** the request to fetch a story's comment tree fails
- **THEN** the comments view shows a failure state and previously cached comments for other stories remain unaffected
