# Incidents Log

## 2026-06-09 — Finnhub Key Pending

**Status:** resolved.
**Impact:** live market-data endpoints were unavailable before the key was provided.
**Resolution:** Finnhub key is configured locally. Search, quote, and company-news endpoints have been verified.

## 2026-06-09 — Finnhub Candle Endpoint Access Limited

**Status:** blocked by Finnhub plan access.
**Impact:** live search, quotes, and news work, but `/stock/candle` returns an access-limit error for the current key.
**Resolution:** app maps this response to a clear unavailable state and uses Twelve Data `/time_series` for chart history instead of Finnhub candles.
**Verification:** AAPL candle requests for current and historical ranges returned the same access-limit response, and AAPL/SPY/QQQ symbol variants all returned the same response, so this is not caused by date parameters or symbol format.

---
