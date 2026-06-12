# Data Registry

## Planned Models

| Model | Purpose |
| --- | --- |
| `Asset` | Symbol, name, exchange, type, identifiers. |
| `AssetQuote` | Current price, absolute change, percent change, timestamp. |
| `ChartPoint` | Timestamped price point for simple charting. |
| `MarketNewsItem` | Headline, source, URL, publish date, summary if available. |
| `AnalysisNote` | Optional short user note for AI context. |
| `ChartScreenshot` | Local selected image metadata and bytes/path handling. |
| `AnalystOutput` | Summary, points, confidence/risk metadata. |
| `MarketAnalysisReport` | Bull, Bear, Risk, Consensus, final disclaimer. |
| `AppSettings` | AI consent state and future local preferences. |

## Planned Services and Repositories

| Area | Responsibility |
| --- | --- |
| Market data repository | Ticker search, quotes, profiles, and news. |
| Chart data repository | Twelve Data time series for chart history. |
| News repository | Recent headlines and source attribution. |
| Watchlist repository | Local saved tickers. |
| Recent search repository | Local search history. |
| Settings repository | Local AI consent state. |
| Gemini service | Direct HTTP request/response handling. |
| Market analysis AI service | Prompt construction and multi-analyst orchestration. |
| Screenshot picker service | Single image acquisition and validation. |

## Persistence

- SharedPreferences is acceptable for watchlist, recent searches, and AI consent.
- Do not store real API keys in SharedPreferences.
- Avoid sending user-entered notes or screenshots to AI until consent is granted.

## Finnhub Runtime Status

- `/search`, `/quote`, `/company-news`, and `/stock/profile2` have been verified with the current key.
- `/stock/candle` is implemented but returns an access-limit response for the current key; see `finnhub_endpoint_matrix.md`.

## Twelve Data Runtime Status

- Asset Details charts use Twelve Data `/time_series` instead of Finnhub `/stock/candle`.
- `TWELVE_DATA_API_KEY` is configured locally for live chart history.
- Demo AAPL daily time series returns OHLCV data.
- Configured key returns AAPL and SPY daily OHLCV data.
