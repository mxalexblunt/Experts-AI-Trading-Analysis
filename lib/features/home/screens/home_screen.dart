import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_number_text.dart';
import '../../../core/widgets/asset_logo_tile.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../features/asset/screens/asset_details_screen.dart';
import '../../../features/shared/widgets/app_status_card.dart';

const _suggestedHomeAssets = [
  AssetModel(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    type: AssetType.stock,
    logoUrl: 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.png',
  ),
  AssetModel(
    symbol: 'NVDA',
    name: 'NVIDIA Corp.',
    type: AssetType.stock,
    logoUrl: 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/NVDA.png',
  ),
  AssetModel(
    symbol: 'GOOGL',
    name: 'Alphabet Inc.',
    type: AssetType.stock,
    logoUrl: 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/GOOG.png',
  ),
  AssetModel(
    symbol: 'MSFT',
    name: 'Microsoft Corp.',
    type: AssetType.stock,
    logoUrl: 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/MSFT.png',
  ),
  AssetModel(
    symbol: 'AMZN',
    name: 'Amazon.com Inc.',
    type: AssetType.stock,
    logoUrl: 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AMZN.png',
  ),
  AssetModel(
    symbol: 'META',
    name: 'Meta Platforms Inc.',
    type: AssetType.stock,
    logoUrl: 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/FB.png',
  ),
  AssetModel(
    symbol: 'TSLA',
    name: 'Tesla Inc.',
    type: AssetType.stock,
    logoUrl: 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/TSLA.png',
  ),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentSearchesProvider);
    final watchlist = ref.watch(watchlistProvider);
    final isFinnhubConfigured = ref.watch(finnhubRepositoryProvider).isConfigured;
    final isTwelveDataConfigured =
        ref.watch(twelveDataChartRepositoryProvider).isConfigured;
    final isMarketDataConfigured = isFinnhubConfigured && isTwelveDataConfigured;
    final marketDataMessage = _marketDataMessage(
      isFinnhubConfigured: isFinnhubConfigured,
      isTwelveDataConfigured: isTwelveDataConfigured,
    );
    final searchResults = _query.length < 2
        ? null
        : ref.watch(assetSearchProvider(_query));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Experts'),
            middle: Text('Experts', style: AppTypography.headline),
            alwaysShowMiddle: false,
            backgroundColor: AppColors.canvas.withValues(alpha: 0.94),
            border: null,
            heroTag: 'home_sliver_navigation_bar',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.large,
              AppSpacing.screenPadding,
              88,
            ),
            sliver: SliverToBoxAdapter(
              child: MotionStaggeredColumn(
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: AppSpacing.xlarge),
                  _SearchPanel(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    onSubmitted: _openTypedSymbol,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  if (searchResults != null) ...[
                    _SearchResults(
                      results: searchResults,
                      onAssetSelected: _openAsset,
                    ),
                    const SizedBox(height: AppSpacing.xlarge),
                  ],
                  _SuggestedAssets(onAssetSelected: _openAsset),
                  const SizedBox(height: AppSpacing.xlarge),
                  _WatchlistPreview(
                    items: watchlist,
                    onAssetSelected: _openAsset,
                  ),
                  const SizedBox(height: AppSpacing.xlarge),
                  _RecentSearches(
                    assets: recent,
                    onAssetSelected: _openAsset,
                  ),
                  const SizedBox(height: AppSpacing.xlarge),
                  AppStatusCard(
                    icon: isMarketDataConfigured
                        ? CupertinoIcons.checkmark_alt_circle
                        : CupertinoIcons.cloud,
                    title: isMarketDataConfigured
                        ? 'Market data connected'
                        : 'Market data pending',
                    message: marketDataMessage,
                    color: isMarketDataConfigured
                        ? AppColors.tradingUp
                        : AppColors.warning,
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _marketDataMessage({
    required bool isFinnhubConfigured,
    required bool isTwelveDataConfigured,
  }) {
    if (isFinnhubConfigured && isTwelveDataConfigured) {
      return 'Finnhub powers search, quotes, and news. Twelve Data powers chart history.';
    }
    if (isFinnhubConfigured) {
      return 'Finnhub is connected. Add a Twelve Data API key to enable chart history.';
    }
    if (isTwelveDataConfigured) {
      return 'Twelve Data is connected. Add a Finnhub API key to enable search, quotes, and news.';
    }
    return 'Add Finnhub and Twelve Data API keys to enable full market data.';
  }

  void _openTypedSymbol(String value) {
    final symbol = value.trim().toUpperCase();
    if (symbol.isEmpty) return;
    _openAsset(
      AssetModel(
        symbol: symbol,
        name: symbol,
        type: AssetType.unknown,
      ),
    );
  }

  void _openAsset(AssetModel asset) {
    ref.read(recentSearchesProvider.notifier).add(asset);
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        settings: const RouteSettings(name: 'AssetDetailsScreen'),
        builder: (_) => AssetDetailsScreen(
          initialAsset: asset,
          onOpenSettings: widget.onOpenSettings,
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Market analysis from multiple AI perspectives.',
      style: AppTypography.body,
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.hero,
      padding: const EdgeInsets.all(AppSpacing.medium),
      radius: 34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SearchVisualPanel(),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'Search stocks and ETFs',
            style: AppTypography.title3,
          ),
          const SizedBox(height: AppSpacing.small),
          CupertinoTextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            placeholder: 'AAPL, TSLA, NVDA, SPY...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: AppSpacing.medium),
              child: Icon(
                CupertinoIcons.search,
                color: AppColors.textTertiary,
                size: 19,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: AppShadows.subtle,
            ),
            style: AppTypography.callout.copyWith(
              color: AppColors.textPrimary,
            ),
            placeholderStyle: AppTypography.callout.copyWith(
              color: AppColors.textTertiary,
            ),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                CupertinoIcons.return_icon,
                color: AppColors.textTertiary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.tiny),
              Expanded(
                child: Text(
                  'Press return to open a ticker directly.',
                  style: AppTypography.footnote,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchVisualPanel extends StatelessWidget {
  const _SearchVisualPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: AppColors.actionDark,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _HomeChartBackdropPainter(
              lineColor: AppColors.primary.withValues(alpha: 0.76),
              fillColor: AppColors.canvasPure.withValues(alpha: 0.04),
              gridColor: AppColors.canvasPure.withValues(alpha: 0.09),
            ),
          ),
          Positioned(
            left: AppSpacing.medium,
            top: AppSpacing.medium,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.canvasPure.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: AppColors.canvasPure.withValues(alpha: 0.16),
                ),
              ),
              child: const Icon(
                CupertinoIcons.sparkles,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.medium,
            top: AppSpacing.medium,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.small,
                vertical: AppSpacing.tiny,
              ),
              decoration: BoxDecoration(
                color: AppColors.canvasPure.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                'Live market lens',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.canvasPure,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.onAssetSelected,
  });

  final AsyncValue<List<AssetModel>> results;
  final ValueChanged<AssetModel> onAssetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Search Results'),
        const SizedBox(height: AppSpacing.small),
        results.when(
          loading: () => const AppCard(
            child: Center(child: MotionLoadingIndicator()),
          ),
          error: (error, _) => AppStatusCard(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: 'Search unavailable',
            message: error is AppError
                ? error.message
                : 'Market search is unavailable right now.',
            color: AppColors.warning,
          ),
          data: (assets) {
            if (assets.isEmpty) {
              return const EmptyState(
                icon: CupertinoIcons.search,
                title: 'No matches',
                message: 'Try a different stock or ETF symbol.',
              );
            }
            return _AssetList(assets: assets, onAssetSelected: onAssetSelected);
          },
        ),
      ],
    );
  }
}

class _WatchlistPreview extends StatelessWidget {
  const _WatchlistPreview({
    required this.items,
    required this.onAssetSelected,
  });

  final List<WatchlistItemModel> items;
  final ValueChanged<AssetModel> onAssetSelected;

  @override
  Widget build(BuildContext context) {
    final assets = items
        .take(3)
        .map(
          (item) => AssetModel(
            symbol: item.symbol,
            name: item.name,
            type: item.type,
          currentPrice: item.lastPrice,
          changePercent: item.changePercent,
          logoUrl: item.logoUrl,
        ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Watchlist',
          subtitle: items.isEmpty
              ? 'Saved assets will appear here.'
              : '${items.length} saved assets',
        ),
        const SizedBox(height: AppSpacing.small),
        if (assets.isEmpty)
          const EmptyState(
            icon: CupertinoIcons.star,
            title: 'No saved assets yet',
            message: 'Open an asset and tap the star to save it.',
          )
        else
          _AssetList(assets: assets, onAssetSelected: onAssetSelected),
      ],
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.assets,
    required this.onAssetSelected,
  });

  final List<AssetModel> assets;
  final ValueChanged<AssetModel> onAssetSelected;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Recent'),
        const SizedBox(height: AppSpacing.small),
        _AssetList(
          assets: assets.take(4).toList(growable: false),
          onAssetSelected: onAssetSelected,
        ),
      ],
    );
  }
}

class _SuggestedAssets extends StatelessWidget {
  const _SuggestedAssets({required this.onAssetSelected});

  final ValueChanged<AssetModel> onAssetSelected;

  @override
  Widget build(BuildContext context) {
    const assets = _suggestedHomeAssets;
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Suggested',
              subtitle: 'Popular examples for the first market-data pass.',
            ),
            const SizedBox(height: AppSpacing.small),
            _AssetList(
              assets: assets,
              onAssetSelected: onAssetSelected,
            ),
          ],
        );
      },
    );
  }
}

class _AssetList extends StatelessWidget {
  const _AssetList({required this.assets, required this.onAssetSelected});

  final List<AssetModel> assets;
  final ValueChanged<AssetModel> onAssetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < assets.length; index++) ...[
          MotionStaggeredListItem(
            position: index,
            child: _AssetReferenceCard(
              asset: assets[index],
              onPressed: onAssetSelected,
            ),
          ),
          if (index != assets.length - 1)
            const SizedBox(height: AppSpacing.medium),
        ],
      ],
    );
  }
}

class _AssetReferenceCard extends StatelessWidget {
  const _AssetReferenceCard({required this.asset, required this.onPressed});

  final AssetModel asset;
  final ValueChanged<AssetModel> onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onPressed: () => onPressed(asset),
      padding: const EdgeInsets.all(AppSpacing.medium),
      style: AppCardStyle.listGroup,
      radius: 34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetVisualPanel(asset: asset),
          const SizedBox(height: AppSpacing.medium),
          Text(
            asset.symbol,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title2,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            asset.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              _AssetMetaPill(
                icon: CupertinoIcons.tag,
                label: _typeLabel(asset.type),
              ),
              const SizedBox(width: AppSpacing.small),
              _AssetMetaPill(
                icon: _changeIcon(asset.changePercent),
                label: _priceLabel(asset),
                animated: _hasAnimatedPriceLabel(asset),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.actionDark,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: AppShadows.control,
                  ),
                  child: Text(
                    'Open asset',
                    style: AppTypography.button.copyWith(
                      color: AppColors.onActionDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.tradingDown,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(AssetType type) {
    return switch (type) {
      AssetType.stock => 'Stock',
      AssetType.etf => 'ETF',
      AssetType.unknown => 'Asset',
    };
  }

  IconData _changeIcon(double? value) {
    if (value == null) return CupertinoIcons.chart_bar_alt_fill;
    return value >= 0 ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right;
  }

  String _priceLabel(AssetModel asset) {
    final price = asset.currentPrice;
    if (price != null) return 'from \$${price.toStringAsFixed(2)}';
    final change = asset.changePercent;
    if (change != null) return '${change.toStringAsFixed(2)}%';
    return 'Market data';
  }

  bool _hasAnimatedPriceLabel(AssetModel asset) {
    return asset.currentPrice != null || asset.changePercent != null;
  }
}

class _AssetVisualPanel extends StatelessWidget {
  const _AssetVisualPanel({required this.asset});

  final AssetModel asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.logoTile,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _HomeChartBackdropPainter(
              lineColor: AppColors.primary.withValues(alpha: 0.85),
              fillColor: AppColors.canvasPure.withValues(alpha: 0.04),
              gridColor: AppColors.canvasPure.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: AppSpacing.medium,
            top: AppSpacing.medium,
            child: AssetLogoTile(
              symbol: asset.symbol,
              type: asset.type,
              logoUrl: asset.logoUrl,
              size: 68,
              showChartFallback: true,
            ),
          ),
          Positioned(
            right: AppSpacing.medium,
            top: AppSpacing.medium,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.canvasPure.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: AppColors.canvasPure.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                CupertinoIcons.heart,
                color: AppColors.canvasPure,
                size: 22,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.medium,
            right: AppSpacing.medium,
            bottom: AppSpacing.medium,
            child: Row(
              children: [
                const Spacer(),
                _VisualBadge(label: _visualBadgeLabel(asset.type)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _visualBadgeLabel(AssetType type) {
    return switch (type) {
      AssetType.stock => 'Equity',
      AssetType.etf => 'Fund',
      AssetType.unknown => 'Watch',
    };
  }
}

class _AssetMetaPill extends StatelessWidget {
  const _AssetMetaPill({
    required this.icon,
    required this.label,
    this.animated = false,
  });

  final IconData icon;
  final String label;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.subhead.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.tiny),
          Flexible(
            child: animated
                ? AnimatedNumberText(
                    value: label,
                    style: style,
                    stagger: const Duration(milliseconds: 14),
                    duration: const Duration(milliseconds: 280),
                    verticalOffset: 0.26,
                    flipBegin: -0.12,
                    scaleDown: true,
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
          ),
        ],
      ),
    );
  }
}

class _VisualBadge extends StatelessWidget {
  const _VisualBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvasPure.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption1.copyWith(
          color: AppColors.canvasPure,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomeChartBackdropPainter extends CustomPainter {
  const _HomeChartBackdropPainter({
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.66,
        size.width * 0.22,
        size.height * 0.38,
        size.width * 0.38,
        size.height * 0.47,
      )
      ..cubicTo(
        size.width * 0.52,
        size.height * 0.55,
        size.width * 0.58,
        size.height * 0.25,
        size.width * 0.72,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.43,
        size.width * 0.88,
        size.height * 0.22,
        size.width,
        size.height * 0.28,
      );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HomeChartBackdropPainter oldDelegate) {
    return lineColor != oldDelegate.lineColor ||
        fillColor != oldDelegate.fillColor ||
        gridColor != oldDelegate.gridColor;
  }
}
