# Twelve Data Chart Provider

Last checked: 2026-06-09

## Purpose

Experts renders charts locally with `fl_chart`. Twelve Data supplies OHLCV chart points through `/time_series`.

## Runtime Configuration

- Runtime define: `TWELVE_DATA_API_KEY`
- Local default key: configured.
- Runtime override: `--dart-define=TWELVE_DATA_API_KEY=...`
- Missing key behavior if the default is removed or overridden with an empty key: Asset Details shows a clear chart unavailable state.

## Timeframe Mapping

| UI Timeframe | Twelve Data Interval | Output Size |
| --- | --- | --- |
| `1D` | `5min` | `78` |
| `1W` | `1day` | `8` |
| `1M` | `1day` | `32` |
| `6M` | `1day` | `132` |
| `1Y` | `1day` | `264` |

## Notes

- Finnhub still powers search, quotes, metadata, and news.
- Finnhub `/stock/candle` remains unavailable on the current Finnhub plan.
- If the Twelve Data free key does not include intraday access, `1D` should remain unavailable rather than showing a fake daily chart.
