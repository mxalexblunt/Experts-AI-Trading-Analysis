# Sprints History

## Integrated MVP Slice — 2026-06-09
**Goal achieved:** partial yes. Implemented core theme, Cupertino shell, domain layer, providers, home, asset details, screenshot upload, AI consent/settings, AI report, watchlist, docs/pipeline artifacts.
**Files created:** core theme/widgets, models, repositories, providers, feature screens, PRD/pipeline/project_map/sprints docs.
**Files modified:** pubspec.yaml, ios/Runner/Info.plist, lib/main.dart, test/widget_test.dart.
**New providers:** settingsProvider, watchlistProvider, recentSearchesProvider, assetSearchProvider, assetDetailsProvider, chartDataProvider, newsProvider, analysisDraftProvider, marketAnalysisProvider.
**New models:** AssetModel, AssetQuoteModel, ChartPointModel, NewsItemModel, WatchlistItemModel, AppSettings, AnalysisRequest, AnalystOutput, MarketAnalysisReport.
**New reusable widgets:** AppButton, AppCard, AppDivider, AppSectionHeader, EmptyState, AppStatusCard, ChartScreenshotField.
**Known blocked work:** Finnhub candle access depends on a key/plan that includes `/stock/candle`.
**Verification:** flutter analyze passes with no issues.
---

## Integration Hardening — 2026-06-09
**Goal achieved:** yes.
**Files modified:** lib/core/services/gemini_service.dart, lib/core/services/market_analysis_ai_service.dart, scripts/update_pipeline.py.
**Changes:** Gemini requests now set `application/json; charset=utf-8`; uploaded chart screenshots are decoded from `AnalysisRequest.chartImageBase64` and sent through `GeminiService.analyzeImage`; pipeline script supports `show`, `complete N`, `skip N`, and `finish`.
**Verification:** `python3 -m py_compile scripts/update_pipeline.py`, `python3 scripts/update_pipeline.py show`, and `flutter analyze` all pass.
**Known blocked work:** Finnhub `/stock/candle` remains access-limited on the current key.
---

## Final Plan Alignment Pass — 2026-06-09
**Goal achieved:** yes for unblocked items.
**Files modified:** README.md, lib/core/services/market_analysis_ai_service.dart, lib/features/report/screens/ai_report_screen.dart, project_map/feature_registry.md.
**Changes:** replaced starter README with Experts-specific setup and runtime key instructions; routed the final Gemini report call through the same image-aware path used by analyst calls; added retry action to the AI Report error state; aligned the feature registry with actual implementation paths.
**Verification:** `flutter analyze`, `python3 -m py_compile scripts/update_pipeline.py`, and `python3 scripts/update_pipeline.py show` pass.
**Known blocked work:** Finnhub `/stock/candle` remains access-limited on the current key; simulator QA remains pending until explicitly run.
---

## Consent Navigation Hardening — 2026-06-09
**Goal achieved:** yes.
**Files modified:** lib/features/home/screens/main_tabs_screen.dart, lib/features/home/screens/home_screen.dart, lib/features/watchlist/screens/watchlist_screen.dart, lib/features/asset/screens/asset_details_screen.dart, lib/features/settings/widgets/ai_consent_dialog.dart.
**Changes:** added an AI consent blocked dialog for users who previously declined consent; the dialog can return users from Asset Details to the Settings tab to re-grant consent. Suggested assets now use the same selection path as search results, so they are persisted in recent searches.
**Verification:** `flutter analyze` passes with no issues; grep found no Material imports, deprecated opacity/minSize APIs, unfinished-work markers, or Russian UI terms in app/docs.
**Known blocked work:** Finnhub `/stock/candle` remains access-limited on the current key; simulator QA remains pending until explicitly run.
---

## Watchlist And Screenshot State Alignment — 2026-06-09
**Goal achieved:** yes.
**Files modified:** lib/features/watchlist/screens/watchlist_screen.dart, lib/models/analysis_request.dart, lib/providers/analysis_providers.dart, lib/features/asset/screens/asset_details_screen.dart, project_map/data_models.md.
**Changes:** Watchlist rows now show added date and no longer repeat the local-only note that belongs in Settings. Screenshot attachment state now stores the selected image path in `AnalysisRequest` via `analysisDraftProvider` alongside base64 and MIME data.
**Verification:** `flutter analyze` passes with no issues; targeted grep confirms `chartImagePath` flows through model, provider, and Asset Details.
**Known blocked work:** Finnhub `/stock/candle` remains access-limited on the current key; simulator QA remains pending until explicitly run.
---

## Finnhub API Pass — 2026-06-09
**Goal achieved:** partial yes.
**Files modified:** lib/repositories/finnhub_repository.dart, lib/models/asset_model.dart, lib/features/home/screens/home_screen.dart, lib/features/settings/screens/settings_screen.dart, lib/models/market_analysis_report.dart, lib/core/services/market_analysis_ai_service.dart, pipeline_state.md, project_map/incidents.md.
**Changes:** configured the provided Finnhub key locally; verified search, quote, and company-news API responses; added `ETP` parsing as ETF; merged `/search` metadata into asset details so ETF names/types survive when `/stock/profile2` is empty; made Home and Settings show connected/pending data-source state dynamically; mapped Finnhub endpoint access-limit errors to a clear unavailable state; aligned the required report/settings disclaimer with the PRD wording.
**Verification:** `flutter analyze` passes with no issues; curl smoke checks confirm SPY search, quote, and news return data.
**Known blocked work:** Finnhub `/stock/candle` returns an access-limit error for the current key, so full live chart data requires a plan/key with stock-candle access. Manual simulator QA remains pending until explicitly run.
---

## Finnhub Details Robustness — 2026-06-09
**Goal achieved:** yes.
**Files modified:** lib/repositories/finnhub_repository.dart, README.md, project_map/manual_qa.md, project_map/sprints_history.md.
**Changes:** made asset details depend on `/quote` while treating `/stock/profile2` and `/search` as best-effort metadata. This keeps quote/details usable if metadata endpoints fail or rate-limit. Updated README and manual QA to reflect the current key status and candle access limit.
**Verification:** `flutter analyze` passes with no issues; grep found no Material imports, deprecated opacity/minSize APIs, unfinished-work markers, or Russian UI terms in app/docs.
**Known blocked work:** Finnhub `/stock/candle` remains access-limited on the current key; simulator QA remains pending until explicitly run.
---

## Flutter E2E Test Pass — 2026-06-09
**Goal achieved:** yes for simulator QA.
**Files modified:** pubspec.yaml, pubspec.lock, lib/core/screen_logger.dart, lib/main.dart, feature navigation routes, lib/features/asset/widgets/chart_screenshot_field.dart, lib/core/services/market_analysis_ai_service.dart, integration_test/*, test_driver/integration_test.dart, project_map/manual_qa.md, pipeline_state.md.
**Changes:** added official Flutter `integration_test` infrastructure, screenshot driver, route logging, named route settings, deterministic E2E-only fake picker and fake AI flags, full MVP flow tests, and navigation safety tests.
**Verification:** `flutter analyze` passes; `flutter test integration_test/app_test.dart` passes 5/5; `flutter test integration_test/navigation_safety_test.dart` passes 2/2; `flutter drive` for both targets passes and saves screenshots. Contact sheet reviewed visually.
**Known blocked work:** Finnhub `/stock/candle` remains access-limited on the current key; native Photos/Camera picker and live Gemini network are intentionally not used in automated E2E.
---

## Twelve Data Chart Provider — 2026-06-09
**Goal achieved:** partial yes.
**Files modified:** lib/repositories/twelve_data_chart_repository.dart, lib/providers/market_data_providers.dart, lib/features/asset/screens/asset_details_screen.dart, lib/features/home/screens/home_screen.dart, lib/features/settings/screens/settings_screen.dart, README.md, pipeline_state.md, project_map/*.
**Changes:** added `TwelveDataChartRepository`, switched `chartDataProvider` from Finnhub candles to Twelve Data `/time_series`, added chart source attribution, and updated Data Sources copy for Finnhub search/quote/news plus Twelve Data charts.
**Verification:** Twelve Data demo AAPL daily time series returns OHLCV data; configured key returns AAPL and SPY daily OHLCV data; `flutter analyze`, widget test, main E2E flow, and navigation safety E2E pass with no issues.
**Known blocked work:** Finnhub `/stock/candle` remains access-limited on the current key.
---
