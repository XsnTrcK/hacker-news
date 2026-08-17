## Purpose

Lets a user land on an existing Hacker News discussion for an article link found inside a comment, instead of always leaving the app, when that discussion can be confidently identified.

## ADDED Requirements

### Requirement: Comment links are checked for an existing HN discussion before external launch
When a user taps a link inside a comment body whose URL is not already a `news.ycombinator.com` item link, the app SHALL check whether an HN discussion exists for that URL before falling back to opening the link externally.

#### Scenario: Non-HN link in a comment triggers a discussion check
- **WHEN** a user taps a link inside a comment body and the link's URL is not a `news.ycombinator.com` item link
- **THEN** the app checks for a matching HN discussion before deciding how to open the link

#### Scenario: HN discussion link in a comment is unaffected
- **WHEN** a user taps a link inside a comment body whose URL is already a `news.ycombinator.com` item link
- **THEN** the app opens the referenced discussion directly, unchanged from existing behavior, without performing this capability's discussion check

### Requirement: A candidate discussion is only accepted on a verified URL match
The app SHALL only treat a candidate HN discussion as a match for the tapped link when the discussion's story URL and the tapped URL are equal after normalization (case-insensitive hostname, no trailing slash, query string and fragment ignored). A candidate with no story URL, or whose normalized hostname or path differs from the tapped URL's, SHALL be rejected.

#### Scenario: Matching URL differing only by query string or trailing slash is accepted
- **WHEN** a candidate discussion's story URL and the tapped URL have the same hostname and path but differ in query string, fragment, or a trailing slash
- **THEN** the candidate is accepted as a match

#### Scenario: Candidate with no story URL is rejected
- **WHEN** a candidate discussion has no story URL (e.g. a self-text post)
- **THEN** the candidate is rejected and treated as no match found

#### Scenario: Candidate with a different hostname or path is rejected
- **WHEN** a candidate discussion's story URL has a hostname or path that differs from the tapped URL's
- **THEN** the candidate is rejected and treated as no match found

### Requirement: A verified match opens the discussion in-app
When a verified matching HN discussion is found for a tapped comment link, the app SHALL open that discussion in-app instead of launching the URL externally.

#### Scenario: Verified match opens the in-app discussion
- **WHEN** the discussion check for a tapped comment link produces a verified match
- **THEN** the app opens that discussion in the same in-app view used for tapping an existing `news.ycombinator.com` item link, without prompting the user for confirmation

### Requirement: No match falls back to the existing external-open behavior
When no verified matching discussion is found for a tapped comment link — including when the check fails or exceeds its time limit — the app SHALL open the link exactly as it does today (external browser/app).

#### Scenario: No matching discussion found
- **WHEN** the discussion check for a tapped comment link completes and finds no verified match
- **THEN** the app opens the link externally, unchanged from today's behavior

#### Scenario: Discussion check fails or times out
- **WHEN** the discussion check for a tapped comment link errors or does not complete within a bounded time limit
- **THEN** the app treats it as no match found and opens the link externally

### Requirement: A pending discussion check is indicated to the user without blocking the comment thread
While a discussion check for a tapped comment link is in progress, the app SHALL show a transient, non-blocking indication that a check is underway, and the user SHALL remain able to scroll and interact with the comment thread during the check.

#### Scenario: Indication shown while check is pending
- **WHEN** a discussion check for a tapped comment link begins
- **THEN** the app shows a transient indication that a check is in progress

#### Scenario: Comment thread remains interactive during the check
- **WHEN** a discussion check for a tapped comment link is in progress
- **THEN** the user can continue scrolling and reading the comment thread without waiting for the check to complete

#### Scenario: Indication clears when the check resolves
- **WHEN** a discussion check for a tapped comment link completes (match, no match, error, or timeout)
- **THEN** the transient indication is dismissed

### Requirement: Scope is limited to comment body links
This capability SHALL apply only to links tapped inside comment bodies. Links tapped elsewhere in the app, including a story's own self-text, are unaffected and retain their existing behavior.

#### Scenario: Article self-text link is unaffected
- **WHEN** a user taps a link inside a story's self-text (not a comment)
- **THEN** the app opens the link using its existing behavior, without performing this capability's discussion check
