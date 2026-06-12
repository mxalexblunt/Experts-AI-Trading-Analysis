# Experts

Experts is a light-only iOS Flutter app for educational US stock and ETF analysis. It combines local watchlists, market context, optional chart screenshots, and a multi-analyst Gemini flow that returns balanced Bull, Bear, Risk, Consensus, and final report sections.

## Product Scope

- iOS-first Flutter app.
- Cupertino-only UI with Riverpod state management.
- US stocks and ETFs for the MVP.
- Local watchlist and settings via SharedPreferences.
- No monetization, accounts, brokerage connection, crypto, or dark theme in the MVP.
- App UI copy must remain English only.

## Runtime Configuration

The MVP has a Finnhub key configured for local development. Runtime defines can still override API keys when needed.

Experts is not affiliated with, endorsed by, or sponsored by Finnhub, Twelve Data, or Google Gemini. The app uses third-party APIs from these providers to retrieve market information and generate educational AI analysis.

```sh
flutter run \
  --dart-define=GOOGLE_API_KEY=your_gemini_key \
  --dart-define=FINNHUB_API_KEY=your_finnhub_key \
  --dart-define=TWELVE_DATA_API_KEY=your_twelve_data_key
```

`GOOGLE_API_KEY` enables Gemini report generation. If it is missing, Experts shows a limited educational fallback report.

`FINNHUB_API_KEY` enables live ticker search, quotes, profiles, and news. The current Finnhub key is verified for search, quotes, and company news. The `/stock/candle` endpoint currently returns a plan access error, so Experts uses Twelve Data for chart history instead.

`TWELVE_DATA_API_KEY` enables Asset Details charts. A Twelve Data key is configured for local development, and runtime defines can override it. Experts uses Twelve Data `/time_series` data and renders the chart locally with `fl_chart`.

## Verification

Allowed in this repository:

```sh
flutter analyze
```

Recommended manual flow after keys are configured:

```sh
flutter run -d <ios-simulator-id>
```

Do not run builds, tests, formatters, or other commands that rewrite files unless explicitly requested.

## Project Documents

- [PRD.md](/Users/infoas/new_projects/experts/PRD.md)
- [DESIGN.md](/Users/infoas/new_projects/experts/DESIGN.md)
- [pipeline_state.md](/Users/infoas/new_projects/experts/pipeline_state.md)
- [project_map/](/Users/infoas/new_projects/experts/project_map/)
