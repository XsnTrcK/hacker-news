# Story Search Specification

## Purpose

Lets users find Hacker News stories by keyword search instead of only browsing the main feed, reusing the existing story list and detail views.

## Requirements

### Requirement: Search entry point via swipe
The app SHALL provide a dedicated search page reachable by swiping left from the News page, regardless of feed mode, with its query text and results preserved as the user navigates away and back.

#### Scenario: User swipes to the search page
- **WHEN** the user swipes left from the News page
- **THEN** a search view is shown, with the query field auto-focused only if it is currently empty

#### Scenario: Search state persists across navigation
- **WHEN** the user swipes away from the search page and back
- **THEN** the previously entered query text and results remain displayed, and the keyboard is not automatically reopened

#### Scenario: Search page reachable regardless of feed mode
- **WHEN** the user's feed mode is set to RSS-only, All, or Hacker News
- **THEN** the search page remains reachable by swiping left from the News page

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
