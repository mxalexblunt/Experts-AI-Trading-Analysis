import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_number_text.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/asset_logo_tile.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../asset/screens/asset_details_screen.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(watchlistProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Watchlist'),
            middle: Text('Watchlist', style: AppTypography.headline),
            alwaysShowMiddle: false,
            backgroundColor: AppColors.canvas.withValues(alpha: 0.94),
            border: null,
            heroTag: 'watchlist_sliver_navigation_bar',
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
                  AppSectionHeader(
                    title: 'Saved Assets',
                    subtitle: items.isEmpty
                        ? 'Saved stocks and ETFs stay on this device.'
                        : '${items.length} saved assets',
                  ),
                  const SizedBox(height: AppSpacing.small),
                  if (items.isEmpty)
                    const EmptyState(
                      icon: CupertinoIcons.star,
                      title: 'No saved assets yet',
                      message:
                          'Search for a stock or ETF, then save it here for faster access.',
                    )
                  else
                    Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          MotionStaggeredListItem(
                            position: index,
                            child: _WatchlistRow(
                              item: items[index],
                              onPressed: () => _openAsset(context, items[index]),
                              onRemove: () => ref
                                  .read(watchlistProvider.notifier)
                                  .removeSymbol(items[index].symbol),
                            ),
                          ),
                          if (index != items.length - 1)
                            const SizedBox(height: AppSpacing.small),
                        ],
                      ],
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

  void _openAsset(BuildContext context, WatchlistItemModel item) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        settings: const RouteSettings(name: 'AssetDetailsScreen'),
        builder: (_) => AssetDetailsScreen(
          initialAsset: AssetModel(
            symbol: item.symbol,
            name: item.name,
            type: item.type,
            currentPrice: item.lastPrice,
            changePercent: item.changePercent,
            logoUrl: item.logoUrl,
          ),
          onOpenSettings: onOpenSettings,
        ),
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({
    required this.item,
    required this.onPressed,
    required this.onRemove,
  });

  final WatchlistItemModel item;
  final VoidCallback onPressed;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final price = item.lastPrice == null
        ? 'No quote'
        : '\$${item.lastPrice!.toStringAsFixed(2)}';
    final change = item.changePercent == null
        ? 'Pending'
        : '${item.changePercent!.toStringAsFixed(2)}%';
    final changeColor = (item.changePercent ?? 0) >= 0
        ? AppColors.tradingUp
        : AppColors.tradingDown;

    return AppCard(
      onPressed: onPressed,
      style: AppCardStyle.listGroup,
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          AssetLogoTile(
            symbol: item.symbol,
            type: item.type,
            logoUrl: item.logoUrl,
            showChartFallback: true,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.symbol, style: AppTypography.headline),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.footnote,
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  'Added ${_dateLabel(item.addedAt)}',
                  style: AppTypography.caption2,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.lastPrice == null)
                Text(price, style: AppTypography.number)
              else
                AnimatedNumberText(
                  value: price,
                  style: AppTypography.number,
                  stagger: const Duration(milliseconds: 18),
                  duration: const Duration(milliseconds: 320),
                  verticalOffset: 0.38,
                  flipBegin: -0.18,
                  scaleDown: true,
                ),
              const SizedBox(height: AppSpacing.micro),
              if (item.changePercent == null)
                Text(
                  change,
                  style: AppTypography.caption1.copyWith(color: changeColor),
                )
              else
                AnimatedNumberText(
                  value: change,
                  style: AppTypography.caption1.copyWith(color: changeColor),
                  stagger: const Duration(milliseconds: 16),
                  duration: const Duration(milliseconds: 280),
                  verticalOffset: 0.28,
                  flipBegin: -0.12,
                  scaleDown: true,
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.small),
          AppIconButton(
            icon: CupertinoIcons.xmark_circle,
            onPressed: onRemove,
            size: 34,
            iconSize: 19,
            backgroundColor: AppColors.surfaceInset,
            foregroundColor: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
