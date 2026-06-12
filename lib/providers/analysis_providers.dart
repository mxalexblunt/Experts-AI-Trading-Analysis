import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/app_error.dart';
import '../core/services/market_analysis_ai_service.dart';
import '../models/models.dart';
import 'settings_provider.dart';

final marketAnalysisAiServiceProvider =
    Provider<MarketAnalysisAiService>((ref) {
  return MarketAnalysisAiService();
});

final analysisDraftProvider =
    StateNotifierProvider<AnalysisDraftNotifier, AnalysisRequest?>((ref) {
  return AnalysisDraftNotifier();
});

final marketAnalysisProvider = StateNotifierProvider<MarketAnalysisNotifier,
    AsyncValue<MarketAnalysisReport?>>((ref) {
  return MarketAnalysisNotifier(ref);
});

class AnalysisDraftNotifier extends StateNotifier<AnalysisRequest?> {
  AnalysisDraftNotifier() : super(null);

  void startFromAsset(AssetModel asset) {
    state = AnalysisRequest(asset: asset);
  }

  void setTimeframe(String timeframe) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(timeframe: timeframe);
  }

  void setChartPoints(List<ChartPointModel> points) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(chartPoints: points);
  }

  void setNewsItems(List<NewsItemModel> items) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(newsItems: items);
  }

  void setUserNote(String? note) {
    final current = state;
    if (current == null) return;
    final trimmed = note?.trim();
    state = current.copyWith(
      userNote: trimmed,
      clearUserNote: trimmed == null || trimmed.isEmpty,
    );
  }

  void attachChartImage({
    required String path,
    required String base64Image,
    String mimeType = 'image/jpeg',
    String? observations,
  }) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      chartImagePath: path,
      chartImageBase64: base64Image,
      chartImageMimeType: mimeType,
      chartObservations: observations,
    );
  }

  void clearChartImage() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(clearChartImage: true);
  }

  void clear() {
    state = null;
  }
}

class MarketAnalysisNotifier
    extends StateNotifier<AsyncValue<MarketAnalysisReport?>> {
  MarketAnalysisNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> generate(AnalysisRequest request) async {
    if (_ref.read(settingsProvider).aiConsentGiven != true) {
      state = AsyncError(AppError.consentRequired(), StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    final service = _ref.read(marketAnalysisAiServiceProvider);
    state = await AsyncValue.guard(() => service.generateFinalReport(request));
  }

  void clear() {
    state = const AsyncData(null);
  }
}
