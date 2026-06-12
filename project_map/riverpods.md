# Providers Registry

| Provider | Type | File | State Shape | Description | Dependencies |
| --- | --- | --- | --- | --- | --- |
| storageServiceProvider | Provider | lib/providers/settings_provider.dart | StorageService | SharedPreferences wrapper | — |
| settingsProvider | StateNotifierProvider | lib/providers/settings_provider.dart | AppSettings | AI consent and local settings | settingsRepositoryProvider |
| watchlistProvider | StateNotifierProvider | lib/providers/watchlist_provider.dart | List<WatchlistItemModel> | Local saved assets | watchlistRepositoryProvider |
| recentSearchesProvider | StateNotifierProvider | lib/providers/recent_searches_provider.dart | List<AssetModel> | Local recent searches | recentSearchRepositoryProvider |
| finnhubRepositoryProvider | Provider | lib/providers/market_data_providers.dart | FinnhubRepository | Market data access with placeholder key | — |
| twelveDataChartRepositoryProvider | Provider | lib/providers/market_data_providers.dart | TwelveDataChartRepository | Chart history access with placeholder key | — |
| assetSearchProvider | FutureProvider.family | lib/providers/market_data_providers.dart | List<AssetModel> | Stock/ETF search | finnhubRepositoryProvider |
| assetDetailsProvider | FutureProvider.family | lib/providers/market_data_providers.dart | AssetModel | Quote/profile details | finnhubRepositoryProvider |
| chartDataProvider | FutureProvider.family | lib/providers/market_data_providers.dart | List<ChartPointModel> | Timeframe chart points | twelveDataChartRepositoryProvider |
| newsProvider | FutureProvider.family | lib/providers/market_data_providers.dart | List<NewsItemModel> | Recent company news | finnhubRepositoryProvider |
| analysisDraftProvider | StateNotifierProvider | lib/providers/analysis_providers.dart | AnalysisRequest? | Draft note/screenshot/chart/news context | — |
| marketAnalysisProvider | StateNotifierProvider | lib/providers/analysis_providers.dart | AsyncValue<MarketAnalysisReport?> | AI report generation state | settingsProvider, marketAnalysisAiServiceProvider |
