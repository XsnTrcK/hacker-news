## ADDED Requirements

### Requirement: Search entry point on the News page
The News page SHALL display a floating search button that opens a dedicated search screen, visible only while viewing Hacker News-backed feeds.

#### Scenario: User opens search from the News page
- **WHEN** the user taps the floating search button while the News page is showing
- **THEN** a full-screen search view opens with an empty query field and no results shown

#### Scenario: Search button hidden in RSS feed mode
- **WHEN** the user's feed mode is set to RSS-only
- **THEN** the floating search button is not shown

#### Scenario: Search button hidden while not viewing the News page
- **WHEN** the user is viewing a page other than the News page (e.g. the side menu)
- **THEN** the floating search button is not shown, regardless of feed mode

### Requirement: Story search by keyword
The system SHALL let the user search Hacker News stories by entering plain query text, returning matching stories ranked by Algolia's default relevance ordering.

#### Scenario: Query returns matches
- **WHEN** the user types a query with at least one matching story and stops typing
- **THEN** the search view displays a list of matching stories, each rendered the same way as stories in the main news feed

#### Scenario: Query returns no matches
- **WHEN** the user types a query that matches no stories
- **THEN** the search view displays an empty-results message instead of a story list

#### Scenario: Query text is debounced
- **WHEN** the user is actively typing
- **THEN** the system SHALL NOT issue a search request for every keystroke; it SHALL wait until typing pauses before issuing a request

### Requirement: Search results reuse existing story detail view
Selecting a search result SHALL open the same detail view used for stories in the main news feed, with no separate rendering path for search results.

#### Scenario: User opens a search result
- **WHEN** the user taps a story in the search results list
- **THEN** the app navigates to the existing story detail view for that story, supporting the same comment-loading and reading behavior as a story opened from the main feed

### Requirement: Ask HN and self-text results are supported
Search results that are Ask HN or other self-text (no external URL) posts SHALL render and open correctly, using the post's body text instead of an external link.

#### Scenario: User opens an Ask HN search result
- **WHEN** a search result has no external URL and instead has self-text content
- **THEN** the app treats it as a self-text post in the results list and detail view, consistent with how Ask HN posts from the main feed are handled

### Requirement: Search failure handling
If the search request fails (network error, upstream failure), the search view SHALL show an error state rather than crash or hang, and SHALL NOT affect the main news feed's state.

#### Scenario: Search API is unreachable
- **WHEN** the search request fails due to a network or server error
- **THEN** the search view displays an error/empty state and the user can retry by editing the query

### Requirement: Search result pagination
The search view SHALL support loading additional pages of results as the user scrolls, consistent with the pagination behavior of the main news feed.

#### Scenario: User scrolls to the bottom of search results
- **WHEN** the user scrolls near the bottom of the current search results and more results are available
- **THEN** the system fetches and appends the next page of matching stories
