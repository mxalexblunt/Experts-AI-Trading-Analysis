# Experts Pipeline State

## Status: IN_PROGRESS
## App Name: Experts
## Total Sprints: 16
## Current Sprint: 14

## Sprint Status
- [X] 0: Planning & Pipeline Setup
- [X] 1: Core Theme & App Shell
- [X] 2: Dependencies, Permissions & Core Services
- [X] 3: Data Models
- [X] 4: Repositories
- [X] 5: Providers Skeleton
- [X] 6: Navigation & Main Tabs
- [X] 7: Home Search Screen
- [X] 8: Asset Details Screen
- [X] 9: Screenshot Upload
- [X] 10: AI Consent & Settings
- [X] 11: Gemini Multi-Analyst AI
- [X] 12: AI Report Screen
- [X] 13: Watchlist
- [ ] 14: Market Data Integration — Finnhub search/quote/news done; charts moved to Twelve Data; Finnhub candles remain unavailable on the current plan
- [X] 15: Legal, App Store Positioning & Doc Viewer
- [X] 16: Polish & Analyze Pass

## Incidents: 2

- Finnhub key is configured locally and verified for search, quote, and company-news endpoints.
- Finnhub `/stock/candle` returns an access-limit error for the current key.
- Asset Details charts now use Twelve Data `/time_series`; a Twelve Data key is configured locally for live chart history.

## Verification

- [X] `flutter analyze` passes with no issues.
- [X] Finnhub API smoke: search, quote, and company news return data for SPY.
- [X] Twelve Data API smoke: demo AAPL daily time series returns OHLCV data.
- [X] Twelve Data API smoke: configured key returns AAPL and SPY daily OHLCV data.
- [X] iOS simulator E2E flow passes via `integration_test`.
- [X] E2E screenshots saved and visually reviewed.
- [X] Twelve Data key configured locally for chart history.
- [X] Verify AAPL/SPY chart history in-app.
- [ ] Sprint 14 Finnhub candle endpoint remains blocked by current Finnhub plan access.
