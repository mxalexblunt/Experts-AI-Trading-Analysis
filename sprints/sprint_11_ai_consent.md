# Sprint 11 - AI Consent

## Goal

Implement the first-use AI data consent gate.

## Checklist

- [x] Show consent dialog only when an AI action is first attempted.
- [x] Persist accepted, declined, and unanswered consent states.
- [x] Block AI actions when consent is declined.
- [x] Provide a path to Settings for re-enabling consent.
- [x] Ensure ticker, market data, news, notes, and screenshots wait behind consent.

## Acceptance Criteria

- No AI request can run without affirmative consent.
- Declining consent stops the current AI action.
- Consent copy mentions Google Gemini and possible data sent.
- Consent copy avoids unverified data-retention claims.

