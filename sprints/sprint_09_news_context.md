# Sprint 9 - News Context

## Goal

Show recent asset news and prepare it for AI context.

## Checklist

- [x] Add news model mapping for headline, source, URL, publish date, and summary/context.
- [x] Add news repository method for selected asset.
- [x] Render a compact news list on Asset Details.
- [x] Add no-news, loading, and error states.
- [x] Prepare sanitized news context for AI prompts.

## Acceptance Criteria

- News includes source and publish date when available.
- No-news state is graceful and does not block analysis.
- AI context uses summaries/headlines without inventing source details.
- Data source attribution requirements are tracked for Settings.

