# Finnhub Endpoint Matrix

Last checked: 2026-06-09

## Documentation Checked

- Finnhub Authentication: https://finnhub.io/docs/api/authentication
- Finnhub Symbol Search: https://finnhub.io/docs/api/symbol-search
- Finnhub Quote: https://finnhub.io/docs/api/quote
- Finnhub Stock Candles: https://finnhub.io/docs/api/stock-candles
- Finnhub Company News: https://finnhub.io/docs/api/company-news

## Runtime Findings

| Endpoint | Purpose | Status With Current Key | App Handling |
| --- | --- | --- | --- |
| `/search` | Symbol lookup for stocks and ETFs | Works for AAPL, SPY, QQQ | Home search and ETF metadata fallback |
| `/quote` | Current price/change snapshot | Works for AAPL, SPY, QQQ | Asset header, watchlist price context |
| `/company-news` | Recent company news | Works for AAPL and SPY | News context and AI request context |
| `/stock/profile2` | Company profile metadata | Works for AAPL, empty for SPY/QQQ ETFs | ETF details fall back to `/search` metadata |
| `/stock/candle` | Historical OHLCV chart data | Access limited for current key | Chart unavailable state with clear message |

## Candle Checks

The current key returns the same access-limit response for:

- `AAPL`
- `AAPL.US`
- `US.AAPL`
- `SPY`
- `SPY.US`
- `QQQ`
- `QQQ.US`
- AAPL historical 2023 and 2024 date ranges

Conclusion: the candle issue is not caused by symbol format or date parameters. Finnhub candle charts require a Finnhub plan/key that includes `/stock/candle`; Experts now uses Twelve Data for app chart history instead.

## Implementation Notes

- Finnhub returns ETF-like instruments as `ETP`; Experts maps that to `AssetType.etf`.
- ETF `/stock/profile2` can be empty, so `FinnhubRepository.getAssetDetails` merges exact-match `/search` metadata with `/quote`.
- Error bodies that say access is unavailable are mapped to `AppErrorType.unavailable`, not authentication failure.
