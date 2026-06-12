# Sprint 4 - Local Persistence

## Goal

Set up local persistence for settings, watchlist, and recent searches.

## Checklist

- [x] Define local keys for AI consent, watchlist, and recent searches.
- [x] Implement settings persistence with `bool? aiConsentGiven`.
- [x] Implement watchlist add/remove/read persistence.
- [x] Implement recent search persistence with reasonable deduping and limits.
- [x] Add provider APIs that hide SharedPreferences details from UI widgets.

## Acceptance Criteria

- AI consent can represent unanswered, accepted, and declined states.
- Watchlist and recent searches survive app restart.
- Persistence code does not store API keys.
- UI remains decoupled from storage implementation details.

