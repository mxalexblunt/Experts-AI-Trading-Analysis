import 'package:flutter/foundation.dart';
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
  int _debugVariantIndex = 0;

  Future<void> generate(AnalysisRequest request) async {
    if (_ref.read(settingsProvider).aiConsentGiven != true) {
      state = AsyncError(AppError.consentRequired(), StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    final service = _ref.read(marketAnalysisAiServiceProvider);
    state = await AsyncValue.guard(() => service.generateFinalReport(request));
  }

  MarketAnalysisReport showDebugReport({int? variantIndex}) {
    if (!kDebugMode) {
      final current = state.valueOrNull;
      if (current != null) return current;
      throw StateError('Debug AI reports are only available in debug mode.');
    }

    _debugVariantIndex = variantIndex ?? _debugVariantIndex;
    final report = _debugReportVariant(_debugVariantIndex);
    state = AsyncData(report);
    return report;
  }

  MarketAnalysisReport showNextDebugReport() {
    _debugVariantIndex = (_debugVariantIndex + 1) % _debugReportVariantCount;
    return showDebugReport(variantIndex: _debugVariantIndex);
  }

  void clear() {
    state = const AsyncData(null);
  }
}

const int _debugReportVariantCount = 4;

MarketAnalysisReport _debugReportVariant(int index) {
  final now = DateTime(2026, 6, 12, 10, 30).add(Duration(minutes: index * 7));
  final variant = index % _debugReportVariantCount;
  final asset = switch (variant) {
    0 => const AssetModel(
        symbol: 'AMZN',
        name: 'Amazon.com Inc',
        type: AssetType.stock,
        exchange: 'NASDAQ',
        currentPrice: 241.51,
        change: 3.51,
        changePercent: 1.47,
        logoUrl: 'https://logo.clearbit.com/amazon.com',
      ),
    1 => const AssetModel(
        symbol: 'NVDA',
        name: 'NVIDIA Corporation With A Very Long Legal Name',
        type: AssetType.stock,
        exchange: 'NASDAQ',
        currentPrice: 198.42,
        change: -11.64,
        changePercent: -5.54,
        logoUrl: 'https://logo.clearbit.com/nvidia.com',
      ),
    2 => const AssetModel(
        symbol: 'SPY',
        name: 'SPDR S&P 500 ETF Trust',
        type: AssetType.etf,
        exchange: 'NYSEARCA',
        currentPrice: 624.08,
        change: 0.18,
        changePercent: 0.03,
        logoUrl: 'https://logo.clearbit.com/ssga.com',
      ),
    _ => const AssetModel(
        symbol: 'MSFT',
        name: 'Microsoft Corporation',
        type: AssetType.stock,
        exchange: 'NASDAQ',
        currentPrice: 390.34,
        change: -7.82,
        changePercent: -1.96,
        logoUrl: 'https://logo.clearbit.com/microsoft.com',
      ),
  };
  final request = AnalysisRequest(
    asset: asset,
    timeframe: switch (variant) {
      1 => '3M',
      2 => '1Y',
      _ => '1M',
    },
    chartPoints: _debugChartPoints(
      start: switch (variant) {
        1 => 226,
        2 => 578,
        3 => 459,
        _ => 236,
      },
      drift: switch (variant) {
        1 => -1.9,
        2 => 0.2,
        3 => -1.1,
        _ => 0.7,
      },
      volatility: switch (variant) {
        1 => 7.4,
        2 => 2.8,
        3 => 5.2,
        _ => 4.6,
      },
      now: now,
    ),
    newsItems: List.generate(
      switch (variant) {
        1 => 249,
        2 => 3,
        _ => 42,
      },
      (itemIndex) => NewsItemModel(
        id: 'debug-news-$variant-$itemIndex',
        headline: 'Debug market context item ${itemIndex + 1}',
        source: 'Debug Feed',
        publishedAt: now.subtract(Duration(hours: itemIndex + 1)),
      ),
    ),
    userNote: variant == 2
        ? 'Stress test: compact ETF report with limited news and a user note.'
        : null,
  );

  final bullCase = _debugOutput(
    role: AnalystRole.bull,
    summary: switch (variant) {
      1 =>
        'Demand for accelerated compute remains structurally strong, but this view intentionally uses a longer paragraph to test summary truncation, tile height, and evidence rows when the analyst gives too much detail for a mobile surface.',
      2 => 'ETF breadth and liquidity keep the constructive case measured.',
      _ =>
        'Cloud strength, advertising momentum, and operational leverage create a constructive upside path if execution remains steady.',
    },
    scenario: MarketScenario.bullish,
    risk: variant == 1 ? RiskLevel.high : RiskLevel.medium,
    confidence: variant == 1 ? 0.72 : 0.66,
    points: [
      'Revenue durability remains supported by core platform demand.',
      'Recent pullback can improve the educational risk/reward setup.',
      'Positive catalysts need confirmation from price action and news flow.',
    ],
  );
  final bearCase = _debugOutput(
    role: AnalystRole.bear,
    summary: switch (variant) {
      2 => 'The cautious case is limited but not absent.',
      _ =>
        'Margin pressure, valuation sensitivity, and macro risk could keep the setup fragile even if the long-term story remains intact.',
    },
    scenario: MarketScenario.bearish,
    risk: variant == 1 ? RiskLevel.high : RiskLevel.medium,
    confidence: variant == 3 ? 0.58 : 0.62,
    points: [
      'The chart can fail if support breaks on elevated volume.',
      'Multiple compression is possible when growth expectations cool.',
      'Macro headlines can overpower company-specific positives.',
    ],
  );
  final centristCase = _debugOutput(
    role: AnalystRole.centrist,
    summary:
        'The balanced case keeps both sides live and avoids over-reading one signal.',
    scenario: MarketScenario.mixed,
    risk: variant == 2 ? RiskLevel.low : RiskLevel.medium,
    confidence: variant == 0 ? 0.65 : 0.54,
    points: [
      'Bullish and bearish signals are both present in the current context.',
      'Confidence should remain moderate until price and news align.',
      'The best educational read is a conditional, scenario-based view.',
    ],
  );
  final leadConclusion = _debugOutput(
    role: AnalystRole.lead,
    summary: switch (variant) {
      1 =>
        'The lead view is deliberately long for layout QA: the expert team sees a high-risk mixed setup where strong secular demand fights valuation pressure, competitive headlines, and a chart that has not yet repaired enough damage. This should stay readable without swallowing the entire screen.',
      2 => 'Lead verdict: low-risk neutral drift with limited context.',
      3 => 'Lead verdict includes partial fallback pressure for banner testing.',
      _ =>
        'Strong platform momentum offsets near-term margin and valuation pressure. The final view is mixed, with moderate risk and evidence that should be monitored rather than treated as a signal.',
    },
    scenario: switch (variant) {
      2 => MarketScenario.neutral,
      _ => MarketScenario.mixed,
    },
    risk: switch (variant) {
      1 => RiskLevel.high,
      2 => RiskLevel.low,
      _ => RiskLevel.medium,
    },
    confidence: switch (variant) {
      1 => 0.48,
      2 => 0.38,
      _ => 0.65,
    },
    points: [
      'Signal: fundamentals remain resilient enough to avoid a one-sided bearish read.',
      'Conflict: valuation, macro pressure, and chart weakness keep risk elevated.',
      'Verdict: wait for confirmation and compare expert disagreement before drawing conclusions.',
    ],
    isFallback: variant == 3,
  );

  return MarketAnalysisReport(
    id: 'debug-report-$variant',
    asset: asset,
    request: request,
    bullCase: bullCase.copyWith(isFallback: variant == 3),
    bearCase: bearCase,
    centristCase: centristCase,
    leadConclusion: leadConclusion,
    finalSummary: leadConclusion.summary,
    scenario: leadConclusion.scenario,
    keyRisks: switch (variant) {
      1 => const [
          'High volatility can cause large layout stress in long risk text rows',
          'Competitive headlines',
          'Valuation reset',
        ],
      2 => const ['Low context depth', 'ETF breadth can mask rotation'],
      _ => const [
          'Margin pressure',
          'Macro sensitivity',
          'Regulatory headlines',
        ],
    },
    disclaimer: defaultReportDisclaimer,
    createdAt: now,
    isFallback: variant == 3,
  );
}

AnalystOutput _debugOutput({
  required AnalystRole role,
  required String summary,
  required MarketScenario scenario,
  required RiskLevel risk,
  required double confidence,
  required List<String> points,
  bool isFallback = false,
}) {
  return AnalystOutput(
    role: role,
    summary: summary,
    points: points,
    confidence: confidence,
    riskLevel: risk,
    scenario: scenario,
    keyRisks: const [
      'Watch for fast changes in market context.',
      'Use the report as educational analysis only.',
    ],
    disclaimer: defaultReportDisclaimer,
    isFallback: isFallback,
  );
}

List<ChartPointModel> _debugChartPoints({
  required double start,
  required double drift,
  required double volatility,
  required DateTime now,
}) {
  var price = start;
  return List.generate(32, (index) {
    final wave = ((index % 7) - 3) * volatility * 0.22;
    price += drift + wave;
    final close = double.parse(price.toStringAsFixed(2));
    return ChartPointModel(
      timestamp: now.subtract(Duration(days: 31 - index)),
      open: close - 0.8,
      close: close,
      high: close + volatility * 0.7,
      low: close - volatility * 0.8,
      volume: 1000000 + index * 32000,
    );
  });
}
