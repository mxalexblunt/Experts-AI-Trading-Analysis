import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/animated_number_text.dart';
import '../../../core/widgets/asset_logo_tile.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../features/report/screens/ai_report_screen.dart';
import '../../../features/settings/widgets/ai_consent_dialog.dart';
import '../../../features/shared/widgets/app_status_card.dart';
import '../widgets/chart_screenshot_field.dart';

class AssetDetailsScreen extends ConsumerStatefulWidget {
  const AssetDetailsScreen({
    super.key,
    required this.initialAsset,
    this.onOpenSettings,
  });

  final AssetModel initialAsset;
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends ConsumerState<AssetDetailsScreen> {
  static const _timeframes = ['1D', '1W', '1M', '6M', '1Y'];
  static const _analysisButtonLabels = [
    'Generating bull forecast',
    'Drafting bear counterpoint',
    'Letting forecasts debate',
    'Comparing expert notes',
    'Asking the Lead Analyst',
    'Polishing final summary',
  ];

  late final TextEditingController _noteController;
  String _timeframe = '1M';
  String? _imagePath;
  bool _isAnalyzing = false;
  int _analysisLabelIndex = 0;
  Timer? _analysisLabelTimer;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _noteController.addListener(_syncNote);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analysisDraftProvider.notifier).startFromAsset(widget.initialAsset);
    });
  }

  @override
  void dispose() {
    _analysisLabelTimer?.cancel();
    _noteController.removeListener(_syncNote);
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(assetDetailsProvider(widget.initialAsset.symbol));
    final chart = ref.watch(
      chartDataProvider(
        ChartDataQuery(symbol: widget.initialAsset.symbol, timeframe: _timeframe),
      ),
    );
    final news = ref.watch(newsProvider(widget.initialAsset.symbol));
    final watchlist = ref.watch(watchlistProvider);
    final asset = details.valueOrNull ?? widget.initialAsset;
    final isHeaderLoading = details.isLoading && asset.currentPrice == null;
    final isSaved = watchlist.any((item) => item.symbol == asset.symbol);

    ref.listen<AsyncValue<List<ChartPointModel>>>(
      chartDataProvider(
        ChartDataQuery(symbol: widget.initialAsset.symbol, timeframe: _timeframe),
      ),
      (_, next) {
        final points = next.valueOrNull;
        if (points != null) {
          ref.read(analysisDraftProvider.notifier).setChartPoints(points);
        }
      },
    );
    ref.listen<AsyncValue<List<NewsItemModel>>>(
      newsProvider(widget.initialAsset.symbol),
      (_, next) {
        final items = next.valueOrNull;
        if (items != null) {
          ref.read(analysisDraftProvider.notifier).setNewsItems(items);
        }
      },
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.canvas,
        middle: Text(asset.symbol, style: AppTypography.headline),
        trailing: AppIconButton(
          size: 40,
          iconSize: 20,
          icon: isSaved ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          foregroundColor: isSaved ? AppColors.primaryPressed : AppColors.textPrimary,
          onPressed: () => ref.read(watchlistProvider.notifier).toggleAsset(asset),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xlarge,
            AppSpacing.screenPadding,
            110,
          ),
          children: [
            MotionStaggeredColumn(
              children: [
                _AssetHeader(
                  asset: asset,
                  isLoading: isHeaderLoading,
                ),
                const SizedBox(height: AppSpacing.xlarge),
                _ChartSection(
                  timeframe: _timeframe,
                  timeframes: _timeframes,
                  chart: chart,
                  isAssetSummaryReady: !isHeaderLoading,
                  onTimeframeChanged: (value) {
                    setState(() => _timeframe = value);
                    ref.read(analysisDraftProvider.notifier).setTimeframe(value);
                  },
                ),
                const SizedBox(height: AppSpacing.xlarge),
                _ScreenshotSection(
                  imagePath: _imagePath,
                  onImagePicked: (image) {
                    setState(() => _imagePath = image.path);
                    ref.read(analysisDraftProvider.notifier).attachChartImage(
                          path: image.path,
                          base64Image: image.base64Image,
                          mimeType: image.mimeType,
                          observations: 'User uploaded a chart screenshot.',
                        );
                  },
                  onRemove: () {
                    setState(() => _imagePath = null);
                    ref.read(analysisDraftProvider.notifier).clearChartImage();
                  },
                ),
                const SizedBox(height: AppSpacing.xlarge),
                _NoteSection(controller: _noteController),
                const SizedBox(height: AppSpacing.xlarge),
                _NewsSection(news: news),
                const SizedBox(height: AppSpacing.xlarge),
                AppButton(
                  label: _isAnalyzing
                      ? _analysisButtonLabels[_analysisLabelIndex]
                      : 'Analyze',
                  icon: CupertinoIcons.sparkles,
                  isLoading: _isAnalyzing,
                  onPressed: _isAnalyzing ? null : () => _analyze(asset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _syncNote() {
    final text = _noteController.text;
    if (text.length > 240) {
      final trimmed = text.substring(0, 240);
      _noteController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      return;
    }
    ref.read(analysisDraftProvider.notifier).setUserNote(text);
  }

  Future<void> _analyze(AssetModel asset) async {
    if (_isAnalyzing) return;

    try {
      if (!await _ensureAnalysisDisclaimerAccepted()) return;
      if (!context.mounted) return;
      if (!await _ensureAiConsent()) return;
      if (!context.mounted) return;

      _startAnalysisButtonLoop();
      final draft = ref.read(analysisDraftProvider) ?? AnalysisRequest(asset: asset);
      final request = draft.copyWith(asset: asset, timeframe: _timeframe);
      await ref.read(marketAnalysisProvider.notifier).generate(request);
      if (!mounted) return;
      _stopAnalysisButtonLoop();
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute<void>(
          settings: const RouteSettings(name: 'AiReportScreen'),
          builder: (_) => AiReportScreen(asset: asset),
        ),
      );
    } finally {
      _stopAnalysisButtonLoop();
    }
  }

  Future<bool> _ensureAnalysisDisclaimerAccepted() async {
    final settings = ref.read(settingsProvider);
    if (settings.educationalDisclaimerAccepted) return true;

    final accepted = await showAiAnalysisDisclaimerDialog(context);
    if (!context.mounted || !accepted) return false;
    await ref
        .read(settingsProvider.notifier)
        .setEducationalDisclaimerAccepted(true);
    return context.mounted;
  }

  Future<bool> _ensureAiConsent() async {
    final settings = ref.read(settingsProvider);
    if (settings.aiConsentGiven == true) return true;

    if (settings.aiConsentGiven == null) {
      final agreed = await showAiConsentDialog(context);
      if (!context.mounted) return false;
      await ref.read(settingsProvider.notifier).setAiConsent(agreed);
      return agreed;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final openSettings = await showAiConsentBlockedDialog(context);
    if (!mounted) return false;
    if (openSettings) {
      rootNavigator.pop();
      widget.onOpenSettings?.call();
    }
    return false;
  }

  void _startAnalysisButtonLoop() {
    _analysisLabelTimer?.cancel();
    setState(() {
      _isAnalyzing = true;
      _analysisLabelIndex = 0;
    });
    _analysisLabelTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _analysisLabelIndex =
            (_analysisLabelIndex + 1) % _analysisButtonLabels.length;
      });
    });
  }

  void _stopAnalysisButtonLoop() {
    if (!_isAnalyzing && _analysisLabelTimer == null) return;
    _analysisLabelTimer?.cancel();
    _analysisLabelTimer = null;
    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _analysisLabelIndex = 0;
    });
  }
}

class _AssetHeader extends StatelessWidget {
  const _AssetHeader({required this.asset, required this.isLoading});

  final AssetModel asset;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final price = asset.currentPrice == null
        ? 'Price unavailable'
        : '\$${asset.currentPrice!.toStringAsFixed(2)}';
    final change = asset.changePercent == null
        ? 'Waiting for Finnhub'
        : '${asset.changePercent!.toStringAsFixed(2)}%';
    final changeColor = (asset.changePercent ?? 0) >= 0
        ? AppColors.tradingUp
        : AppColors.tradingDown;

    return AppCard(
      style: AppCardStyle.hero,
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetLogoTile(
            symbol: asset.symbol,
            type: asset.type,
            logoUrl: asset.logoUrl,
            size: 68,
            showChartFallback: true,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name, style: AppTypography.title2),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  '${asset.symbol} · ${asset.type.name.toUpperCase()} · ${asset.currency}',
                  style: AppTypography.footnote,
                ),
                const SizedBox(height: AppSpacing.large),
                if (isLoading)
                  const _PriceLoadingText()
                else if (asset.currentPrice == null)
                  Text(price, style: AppTypography.numberLarge)
                else
                  AnimatedNumberText(
                    value: price,
                    style: AppTypography.numberLarge,
                  ),
                const SizedBox(height: AppSpacing.micro),
                if (isLoading)
                  const _PriceLoadingLine()
                else if (asset.changePercent == null)
                  Text(
                    change,
                    style: AppTypography.number.copyWith(color: changeColor),
                  )
                else
                  AnimatedNumberText(
                    value: change,
                    style: AppTypography.number.copyWith(color: changeColor),
                    stagger: const Duration(milliseconds: 18),
                    duration: const Duration(milliseconds: 300),
                    verticalOffset: 0.38,
                    flipBegin: -0.18,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLoadingText extends StatelessWidget {
  const _PriceLoadingText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Loading',
      style: AppTypography.numberLarge.copyWith(
        color: AppColors.textTertiary,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          colors: [
            AppColors.textTertiary.withValues(alpha: 0.42),
            AppColors.textPrimary,
            AppColors.textTertiary.withValues(alpha: 0.42),
          ],
          stops: const [0.18, 0.5, 0.82],
          size: 0.7,
          angle: 0,
          blendMode: BlendMode.srcIn,
        );
  }
}

class _PriceLoadingLine extends StatelessWidget {
  const _PriceLoadingLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          color: AppColors.canvasPure.withValues(alpha: 0.68),
        );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.timeframe,
    required this.timeframes,
    required this.chart,
    required this.isAssetSummaryReady,
    required this.onTimeframeChanged,
  });

  final String timeframe;
  final List<String> timeframes;
  final AsyncValue<List<ChartPointModel>> chart;
  final bool isAssetSummaryReady;
  final ValueChanged<String> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Chart'),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          style: AppCardStyle.elevated,
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            children: [
              if (!isAssetSummaryReady)
                const _ChartLoadingPanel()
              else
                chart.when(
                  loading: () => const _ChartLoadingPanel(),
                  error: (error, _) => SizedBox(
                    height: 180,
                    child: AppStatusCard(
                      icon: CupertinoIcons.chart_bar,
                      title: 'Chart unavailable',
                      message: error is AppError
                          ? error.message
                          : 'Chart data is unavailable right now.',
                      color: AppColors.warning,
                    ),
                  ),
                  data: (points) => points.length < 2
                      ? const SizedBox(height: 180, child: _ChartEmptyState())
                      : _ChartPanel(points: points, timeframe: timeframe),
                ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                children: [
                  for (final item in timeframes)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => onTimeframeChanged(item),
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            curve: AppMotion.curve,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: item == timeframe
                                  ? AppColors.actionDark
                                  : AppColors.surfaceInset,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.fast,
                              curve: AppMotion.curve,
                              style: AppTypography.caption1.copyWith(
                                color: item == timeframe
                                    ? AppColors.onActionDark
                                    : AppColors.textPrimary,
                              ),
                              child: Text(
                                item,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  timeframe == '1D'
                      ? 'Chart: Twelve Data intraday'
                      : 'Chart: Twelve Data daily history',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartLoadingPanel extends StatelessWidget {
  const _ChartLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(child: MotionLoadingIndicator()),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.points,
    required this.timeframe,
  });

  final List<ChartPointModel> points;
  final String timeframe;

  @override
  Widget build(BuildContext context) {
    final stats = _ChartStats.from(points);
    final changeColor = stats.change >= 0
        ? AppColors.tradingUp
        : AppColors.tradingDown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _ChartMetric(
                label: 'Last',
                value: _formatPrice(stats.last),
              ),
            ),
            Expanded(
              child: _ChartMetric(
                label: '$timeframe change',
                value:
                    '${stats.change >= 0 ? '+' : ''}${_formatPrice(stats.change)} '
                    '(${stats.changePercent >= 0 ? '+' : ''}'
                    '${stats.changePercent.toStringAsFixed(2)}%)',
                color: changeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        AnimatedNumberText(
          value: 'Range ${_formatPrice(stats.low)} - ${_formatPrice(stats.high)}',
          style: AppTypography.caption1.copyWith(color: AppColors.textTertiary),
          stagger: const Duration(milliseconds: 9),
          duration: const Duration(milliseconds: 260),
          verticalOffset: 0.18,
          flipBegin: -0.06,
          scaleDown: true,
        ),
        const SizedBox(height: AppSpacing.medium),
        SizedBox(
          height: 220,
          child: LineChart(_lineData(points, stats)),
        ),
      ],
    );
  }

  LineChartData _lineData(List<ChartPointModel> points, _ChartStats stats) {
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].close),
    ];
    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: stats.minY,
      maxY: stats.maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: stats.yInterval,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: AppColors.divider,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles()),
        rightTitles: const AxisTitles(sideTitles: SideTitles()),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            interval: stats.yInterval,
            maxIncluded: false,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              space: 6,
              child: Text(
                _formatCompactPrice(value),
                style: AppTypography.caption2.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: stats.xInterval,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                space: 8,
                fitInside: SideTitleFitInsideData.fromTitleMeta(
                  meta,
                  distanceFromEdge: 8,
                ),
                child: Text(
                  _formatDate(points[index].timestamp),
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.ink,
          tooltipBorderRadius: BorderRadius.circular(AppRadii.sm),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.tiny,
          ),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final index = spot.x.round().clamp(0, points.length - 1);
              final point = points[index];
              return LineTooltipItem(
                '${_formatDate(point.timestamp)}\n${_formatPrice(point.close)}',
                AppTypography.caption1.copyWith(color: AppColors.canvasPure),
                textAlign: TextAlign.left,
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: stats.change >= 0 ? AppColors.tradingUp : AppColors.tradingDown,
          barWidth: 2.4,
          isCurved: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _ChartMetric extends StatelessWidget {
  const _ChartMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTypography.number.copyWith(
      color: color ?? AppColors.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedNumberText(
          value: label,
          style: AppTypography.caption1,
          stagger: const Duration(milliseconds: 12),
          duration: const Duration(milliseconds: 240),
          verticalOffset: 0.22,
          flipBegin: -0.08,
          scaleDown: true,
        ),
        const SizedBox(height: AppSpacing.micro),
        AnimatedNumberText(
          value: value,
          style: valueStyle,
          stagger: const Duration(milliseconds: 18),
          duration: const Duration(milliseconds: 320),
          verticalOffset: 0.38,
          flipBegin: -0.18,
          scaleDown: true,
        ),
      ],
    );
  }
}

class _ChartStats {
  const _ChartStats({
    required this.first,
    required this.last,
    required this.low,
    required this.high,
    required this.change,
    required this.changePercent,
    required this.minY,
    required this.maxY,
    required this.yInterval,
    required this.xInterval,
  });

  final double first;
  final double last;
  final double low;
  final double high;
  final double change;
  final double changePercent;
  final double minY;
  final double maxY;
  final double yInterval;
  final double xInterval;

  factory _ChartStats.from(List<ChartPointModel> points) {
    final closes = [for (final point in points) point.close];
    final low = closes.reduce(math.min);
    final high = closes.reduce(math.max);
    final first = closes.first;
    final last = closes.last;
    final range = math.max(high - low, math.max(last.abs() * 0.01, 1));
    final padding = range * 0.12;
    final minY = low - padding;
    final maxY = high + padding;
    final yInterval = _niceInterval((maxY - minY) / 4);
    final xInterval = math.max(1.0, (points.length - 1) / 2);
    final change = last - first;
    final changePercent = first == 0 ? 0.0 : change / first * 100;

    return _ChartStats(
      first: first,
      last: last,
      low: low,
      high: high,
      change: change,
      changePercent: changePercent,
      minY: minY,
      maxY: maxY,
      yInterval: yInterval,
      xInterval: xInterval,
    );
  }
}

double _niceInterval(double raw) {
  if (raw <= 0) return 1;
  final exponent = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final fraction = raw / exponent;
  final niceFraction = fraction <= 1
      ? 1
      : fraction <= 2
          ? 2
          : fraction <= 5
              ? 5
              : 10;
  return niceFraction * exponent;
}

String _formatPrice(double value) {
  return '\$${value.toStringAsFixed(value.abs() >= 100 ? 2 : 3)}';
}

String _formatCompactPrice(double value) {
  if (value.abs() >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
  return '\$${value.toStringAsFixed(value.abs() >= 100 ? 0 : 1)}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Chart will appear after market data is connected.',
        textAlign: TextAlign.center,
        style: AppTypography.footnote,
      ),
    );
  }
}

class _ScreenshotSection extends StatelessWidget {
  const _ScreenshotSection({
    required this.imagePath,
    required this.onImagePicked,
    required this.onRemove,
  });

  final String? imagePath;
  final ValueChanged<PickedChartImage> onImagePicked;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Chart Screenshot',
          subtitle: 'Optional visual context for the AI analysts.',
        ),
        const SizedBox(height: AppSpacing.small),
        ChartScreenshotField(
          imagePath: imagePath,
          onImagePicked: onImagePicked,
          onRemove: onRemove,
        ),
      ],
    );
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Analysis Note',
          subtitle: 'Optional. Helps focus the educational report.',
        ),
        const SizedBox(height: AppSpacing.small),
        CupertinoTextField(
          controller: controller,
          maxLines: 4,
          maxLength: 240,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          placeholder: 'Add context for this analysis',
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.subtle,
          ),
          style: AppTypography.callout.copyWith(color: AppColors.textPrimary),
          placeholderStyle: AppTypography.callout.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _NewsSection extends StatelessWidget {
  const _NewsSection({required this.news});

  final AsyncValue<List<NewsItemModel>> news;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'News Context'),
        const SizedBox(height: AppSpacing.small),
        news.when(
          loading: () => const AppCard(
            child: Center(child: MotionLoadingIndicator()),
          ),
          error: (error, _) => AppStatusCard(
            icon: CupertinoIcons.news,
            title: 'News unavailable',
            message: error is AppError
                ? error.message
                : 'Recent news is unavailable right now.',
            color: AppColors.warning,
          ),
          data: (items) {
            if (items.isEmpty) {
              return const AppStatusCard(
                icon: CupertinoIcons.news,
                title: 'No recent news',
                message: 'The AI report can still use price and chart context.',
              );
            }
            final visibleItems = items.take(3).toList(growable: false);
            return AppCard(
              style: AppCardStyle.inset,
              child: MotionStaggeredColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < visibleItems.length; index++) ...[
                    _NewsItemRow(item: visibleItems[index]),
                    if (index != visibleItems.length - 1)
                      const SizedBox(height: AppSpacing.medium),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NewsItemRow extends StatelessWidget {
  const _NewsItemRow({required this.item});

  final NewsItemModel item;

  @override
  Widget build(BuildContext context) {
    final uri = _newsUri(item.url);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.headline, style: AppTypography.headline),
              const SizedBox(height: AppSpacing.micro),
              Text(
                item.source ?? 'Market source',
                style: AppTypography.footnote,
              ),
            ],
          ),
        ),
        if (uri != null) ...[
          const SizedBox(width: AppSpacing.small),
          const Icon(
            CupertinoIcons.arrow_up_right,
            color: AppColors.textTertiary,
            size: 17,
          ),
        ],
      ],
    );

    if (uri == null) return content;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.72,
      alignment: Alignment.centerLeft,
      onPressed: () => _confirmOpenNewsUrl(context, uri),
      child: content,
    );
  }

  Uri? _newsUri(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  Future<void> _confirmOpenNewsUrl(BuildContext context, Uri uri) async {
    final shouldOpen = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Open external link?'),
          content: Text(
            'Do you want to open ${uri.toString()} in an external browser?',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true) return;
    await _openNewsUrl(uri);
  }

  Future<void> _openNewsUrl(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
