# Sprint 12 - Gemini Foundation

## Goal

Create the direct HTTP Gemini service foundation.

## Checklist

- [x] Implement API request construction with `dart:io` `HttpClient`.
- [x] Encode requests with `dart:convert` and UTF-8.
- [x] Add JSON response mode support for structured outputs.
- [x] Add safe error mapping for network, auth, quota, and malformed response failures.
- [x] Keep API keys out of logs, docs, and final user-facing messages.

## Acceptance Criteria

- Gemini calls are isolated in a service layer.
- No AI SDK package is used.
- Errors are actionable without exposing secrets.
- Service can support text and image-context analysis paths needed by later reports.

