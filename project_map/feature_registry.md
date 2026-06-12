# Feature Registry

## MVP Features

| Feature | Purpose | Planned Area | Sprint |
| --- | --- | --- | --- |
| App foundation | Cupertino app, routing, shared providers | `lib/core`, app entry | 1, 3 |
| Design system | Centralized light fintech tokens | `lib/core/theme` | 2 |
| Home search | Search stocks/ETFs and show recent assets | `lib/features/home` | 6 |
| Watchlist | Save tickers locally | `lib/features/watchlist`, shared storage | 4, 6, 7 |
| Market data | Fetch Finnhub quote/profile/news data and Twelve Data chart history | `lib/repositories`, `lib/providers/market_data_providers.dart`, `lib/models` | 5, 7, 8 |
| Asset details | Price, movement, chart, analyze entry | `lib/features/asset` | 7 |
| Chart | Simple timeframe chart rendered locally from Twelve Data points | `lib/features/asset/screens/asset_details_screen.dart` | 8 |
| News | Recent headlines and source attribution | `lib/features/asset/screens/asset_details_screen.dart` | 9 |
| Screenshot upload | Single chart image input | `lib/features/asset/widgets/chart_screenshot_field.dart` | 10 |
| AI consent | First-use consent gate and settings toggle | `lib/features/settings`, AI flow | 11, 14 |
| Gemini service | Direct HTTP AI provider | `lib/core/services/gemini_service.dart`, `lib/core/services/market_analysis_ai_service.dart` | 12 |
| Multi-analyst report | Bull, Bear, Risk, Consensus, final report | `lib/features/report` | 13 |
| Settings/legal | AI Privacy, data sources, disclaimer | `lib/features/settings` | 14 |
| Polish | Empty, loading, error, accessibility states | all features | 15 |
| Release readiness | App Store-safe final pass | docs, iOS config, QA checklist | 16 |

## Out of Scope for MVP

- Crypto.
- Brokerage connection.
- Accounts and cloud sync.
- Subscriptions, paid plans, ads, or premium tiers.
- Social/community features.
- Dark mode.
