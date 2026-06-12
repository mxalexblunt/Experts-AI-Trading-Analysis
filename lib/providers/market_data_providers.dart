import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../repositories/finnhub_repository.dart';
import '../repositories/twelve_data_chart_repository.dart';
import 'recent_searches_provider.dart';

class ChartDataQuery {
  const ChartDataQuery({
    required this.symbol,
    this.timeframe = '1M',
  });

  final String symbol;
  final String timeframe;

  @override
  bool operator ==(Object other) {
    return other is ChartDataQuery &&
        other.symbol == symbol &&
        other.timeframe == timeframe;
  }

  @override
  int get hashCode => Object.hash(symbol, timeframe);
}

final finnhubRepositoryProvider = Provider<FinnhubRepository>((ref) {
  final repository = FinnhubRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final twelveDataChartRepositoryProvider =
    Provider<TwelveDataChartRepository>((ref) {
  final repository = TwelveDataChartRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final assetSearchProvider =
    FutureProvider.family<List<AssetModel>, String>((ref, query) {
  return ref.watch(finnhubRepositoryProvider).searchAssets(query);
});

final assetDetailsProvider =
    FutureProvider.family<AssetModel, String>((ref, symbol) async {
  final asset = await ref.watch(finnhubRepositoryProvider).getAssetDetails(
        symbol,
      );
  await ref.read(recentSearchesProvider.notifier).add(asset);
  return asset;
});

final chartDataProvider =
    FutureProvider.family<List<ChartPointModel>, ChartDataQuery>((ref, query) {
  return ref.watch(twelveDataChartRepositoryProvider).getChartData(
        symbol: query.symbol,
        timeframe: query.timeframe,
      );
});

final newsProvider =
    FutureProvider.family<List<NewsItemModel>, String>((ref, symbol) {
  return ref.watch(finnhubRepositoryProvider).getNews(symbol);
});
