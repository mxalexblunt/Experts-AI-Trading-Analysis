import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_number_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/asset_logo_tile.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../features/shared/widgets/app_status_card.dart';

class AiReportScreen extends ConsumerWidget {
  const AiReportScreen({super.key, required this.asset});

  final AssetModel asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(marketAnalysisProvider);
    final draft = ref.watch(analysisDraftProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.canvas,
        middle: Text('AI Report', style: AppTypography.headline),
      ),
      child: SafeArea(
        bottom: false,
        child: reportState.when(
          loading: () => const _ReportLoading(),
          error: (error, _) => _ReportError(
            error: error,
            onRetry: draft == null
                ? null
                : () {
                    final request = draft.copyWith(asset: asset);
                    ref.read(marketAnalysisProvider.notifier).generate(request);
                  },
          ),
          data: (report) {
            if (report == null) {
              return _ReportEmpty(asset: asset);
            }
            return _ReportContent(report: report);
          },
        ),
      ),
    );
  }
}

class _ReportLoading extends StatelessWidget {
  const _ReportLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MotionLoadingIndicator(radius: 14),
          const SizedBox(height: AppSpacing.medium),
          MotionFadeSlide(
            delay: const Duration(milliseconds: 90),
            verticalOffset: 0.012,
            child: Text(
              'Building analyst perspectives...',
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is AppError
        ? (error as AppError).message
        : 'The report could not be generated.';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        MotionStaggeredColumn(
          children: [
            AppStatusCard(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: 'Analysis unavailable',
              message: message,
              color: AppColors.warning,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.medium),
              AppButton(
                label: 'Retry',
                icon: CupertinoIcons.arrow_clockwise,
                style: AppButtonStyle.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ReportEmpty extends StatelessWidget {
  const _ReportEmpty({required this.asset});

  final AssetModel asset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        MotionStaggeredColumn(
          children: [
            AppStatusCard(
              icon: CupertinoIcons.doc_text_search,
              title: 'No report yet',
              message: 'Return to ${asset.symbol} and run an analysis.',
            ),
          ],
        ),
      ],
    );
  }
}

enum _ReportTab { lead, bull, bear, centrist }

class _ReportContent extends StatefulWidget {
  const _ReportContent({required this.report});

  final MarketAnalysisReport report;

  @override
  State<_ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<_ReportContent> {
  _ReportTab _selectedTab = _ReportTab.lead;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xlarge,
        AppSpacing.screenPadding,
        80,
      ),
      children: [
        MotionStaggeredColumn(
          children: [
            _ReportHeader(report: report),
            const SizedBox(height: AppSpacing.xlarge),
            _RoleSelector(
              selectedTab: _selectedTab,
              onChanged: (value) => setState(() => _selectedTab = value),
            ),
            const SizedBox(height: AppSpacing.xlarge),
            AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.curve,
              switchOutCurve: AppMotion.curve,
              child: _SelectedRoleView(
                key: ValueKey(_selectedTab),
                report: report,
                tab: _selectedTab,
              ),
            ),
            const SizedBox(height: AppSpacing.xlarge),
            _ContextCard(report: report),
            const SizedBox(height: AppSpacing.xlarge),
            AppStatusCard(
              icon: CupertinoIcons.info,
              title: 'Educational disclaimer',
              message: report.disclaimer,
            ),
            if (report.isFallback) ...[
              const SizedBox(height: AppSpacing.medium),
              AppStatusCard(
                icon: CupertinoIcons.exclamationmark_triangle,
                title: 'Partial AI fallback',
                message: _fallbackMessage(report),
                color: AppColors.warning,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedTab, required this.onChanged});

  final _ReportTab selectedTab;
  final ValueChanged<_ReportTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<_ReportTab>(
      groupValue: selectedTab,
      backgroundColor: AppColors.surfaceSoft,
      thumbColor: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.micro),
      onValueChanged: (value) {
        if (value != null) onChanged(value);
      },
      children: {
        for (final tab in _ReportTab.values)
          tab: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.tiny,
              vertical: AppSpacing.tiny,
            ),
            child: Text(
              _tabLabel(tab),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption1.copyWith(
                color: tab == selectedTab
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
      },
    );
  }
}

class _SelectedRoleView extends StatelessWidget {
  const _SelectedRoleView({super.key, required this.report, required this.tab});

  final MarketAnalysisReport report;
  final _ReportTab tab;

  @override
  Widget build(BuildContext context) {
    final output = _outputForTab(report, tab);
    final isLead = tab == _ReportTab.lead;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoleSummaryCard(report: report, tab: tab, output: output),
        const SizedBox(height: AppSpacing.xlarge),
        _PointsSection(output: output, isLead: isLead),
        const SizedBox(height: AppSpacing.xlarge),
        _RisksSection(report: report, output: output, isLead: isLead),
        const SizedBox(height: AppSpacing.xlarge),
        if (isLead)
          _TeamComparisonSection(report: report)
        else
          _RoleFocusSection(tab: tab),
      ],
    );
  }
}

class _RoleSummaryCard extends StatelessWidget {
  const _RoleSummaryCard({
    required this.report,
    required this.tab,
    required this.output,
  });

  final MarketAnalysisReport report;
  final _ReportTab tab;
  final AnalystOutput output;

  @override
  Widget build(BuildContext context) {
    final meta = _Meta.forRole(output);
    final summary = tab == _ReportTab.lead ? report.finalSummary : output.summary;

    return AppCard(
      style: AppCardStyle.hero,
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AccentIcon(icon: meta.icon, color: meta.color),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.title, style: AppTypography.title3),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      _roleSubtitle(tab),
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.tiny,
            runSpacing: AppSpacing.tiny,
            children: [
              _RiskLevelChip(riskLevel: output.riskLevel),
              _ScenarioChip(
                scenario: tab == _ReportTab.lead ? report.scenario : output.scenario,
              ),
              if (output.confidence != null)
                _MetricChip(
                  label: 'Confidence',
                  value: _confidenceLabel(output.confidence!),
                  animatedValue: true,
                ),
              _MetricChip(
                label: 'Evidence',
                value: '${output.points.length} points',
                color: AppColors.info,
              ),
              if (output.isFallback)
                const _MetricChip(
                  label: 'Status',
                  value: 'Fallback',
                  color: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Text(summary, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _PointsSection extends StatelessWidget {
  const _PointsSection({required this.output, required this.isLead});

  final AnalystOutput output;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final points = output.points;
    if (points.isEmpty) {
      return const AppStatusCard(
        icon: CupertinoIcons.doc_text,
        title: 'No detailed notes',
        message: 'This role returned a summary without separate evidence points.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: isLead ? 'Lead Notes' : 'Evidence Points'),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          style: AppCardStyle.listGroup,
          child: MotionStaggeredColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < points.length; index++)
                _NumberedPoint(index: index + 1, text: points[index]),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberedPoint extends StatelessWidget {
  const _NumberedPoint({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text('$index', style: AppTypography.caption1),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(text, style: AppTypography.callout)),
        ],
      ),
    );
  }
}

class _RisksSection extends StatelessWidget {
  const _RisksSection({
    required this.report,
    required this.output,
    required this.isLead,
  });

  final MarketAnalysisReport report;
  final AnalystOutput output;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final risks = isLead && report.keyRisks.isNotEmpty
        ? report.keyRisks
        : output.keyRisks;
    if (risks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Risk Watch'),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          style: AppCardStyle.inset,
          child: MotionStaggeredColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final risk in risks)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.tiny),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.tiny),
                      Expanded(child: Text(risk, style: AppTypography.callout)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamComparisonSection extends StatelessWidget {
  const _TeamComparisonSection({required this.report});

  final MarketAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Team Comparison'),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          style: AppCardStyle.listGroup,
          child: Column(
            children: [
              _ComparisonRow(output: report.bullCase),
              const _SoftDivider(),
              _ComparisonRow(output: report.bearCase),
              const _SoftDivider(),
              _ComparisonRow(output: report.centristCase),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.output});

  final AnalystOutput output;

  @override
  Widget build(BuildContext context) {
    final meta = _Meta.forRole(output);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.tiny),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentIcon(icon: meta.icon, color: meta.color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(meta.title, style: AppTypography.headline)),
                    _ScenarioChip(scenario: output.scenario, showLabel: false),
                  ],
                ),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  output.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFocusSection extends StatelessWidget {
  const _RoleFocusSection({required this.tab});

  final _ReportTab tab;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.inset,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.info_circle, color: AppColors.info, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role Focus', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.tiny),
                Text(_roleFocus(tab), style: AppTypography.callout),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.tiny),
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.divider),
        child: SizedBox(height: 1),
      ),
    );
  }
}

AnalystOutput _outputForTab(MarketAnalysisReport report, _ReportTab tab) {
  return switch (tab) {
    _ReportTab.lead => report.leadConclusion,
    _ReportTab.bull => report.bullCase,
    _ReportTab.bear => report.bearCase,
    _ReportTab.centrist => report.centristCase,
  };
}

String _tabLabel(_ReportTab tab) {
  return switch (tab) {
    _ReportTab.lead => 'Lead',
    _ReportTab.bull => 'Bull',
    _ReportTab.bear => 'Bear',
    _ReportTab.centrist => 'Centrist',
  };
}

String _roleSubtitle(_ReportTab tab) {
  return switch (tab) {
    _ReportTab.lead => 'Final arbitration across the expert team',
    _ReportTab.bull => 'Constructive evidence and upside conditions',
    _ReportTab.bear => 'Downside pressure and weakness checks',
    _ReportTab.centrist => 'Balanced base case and uncertainty review',
  };
}

String _roleFocus(_ReportTab tab) {
  return switch (tab) {
    _ReportTab.lead =>
      'The lead view weighs conflicts between experts, chooses the final scenario, and highlights the risks that matter most.',
    _ReportTab.bull =>
      'The bull expert looks for constructive price action, supportive news, and conditions that could keep momentum intact.',
    _ReportTab.bear =>
      'The bear expert checks weak momentum, negative catalysts, and market pressure that could undermine the setup.',
    _ReportTab.centrist =>
      'The centrist expert keeps the base case grounded by comparing both sides and calling out uncertainty.',
  };
}

String _fallbackMessage(MarketAnalysisReport report) {
  final roles = [
    if (report.bullCase.isFallback) 'Bull Expert',
    if (report.bearCase.isFallback) 'Bear Expert',
    if (report.centristCase.isFallback) 'Centrist Expert',
    if (report.leadConclusion.isFallback) 'Lead Analyst',
  ];
  if (roles.isEmpty) {
    return 'Some AI output used limited fallback text. Check the AI logs for the exact reason.';
  }
  return 'Fallback text was used for ${roles.join(', ')}. Check the AI logs for the exact reason.';
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final MarketAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.hero,
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetLogoTile(
            symbol: report.asset.symbol,
            type: report.asset.type,
            logoUrl: report.asset.logoUrl,
            size: 64,
            showChartFallback: true,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.asset.symbol, style: AppTypography.largeTitle),
                const SizedBox(height: AppSpacing.tiny),
                Text(report.asset.name, style: AppTypography.body),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Generated ${_dateLabel(report.createdAt)}',
                  style: AppTypography.footnote,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.report});

  final MarketAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final price = report.asset.currentPrice == null
        ? 'Unavailable'
        : _formatPrice(report.asset.currentPrice!);
    final change = report.asset.changePercent == null
        ? 'Unavailable'
        : _formatPercent(report.asset.changePercent!);

    return AppCard(
      style: AppCardStyle.inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Context Snapshot', style: AppTypography.headline),
          const SizedBox(height: AppSpacing.small),
          _ContextLine(label: 'Asset', value: report.asset.symbol),
          _ContextLine(label: 'Last price', value: price),
          _ContextLine(label: 'Change', value: change),
          _ContextLine(
            label: 'Timeframe',
            value: report.request.timeframe,
          ),
          _ContextLine(
            label: 'Chart points',
            value: '${report.request.chartPoints.length}',
            animatedValue: true,
          ),
          _ContextLine(
            label: 'News items',
            value: '${report.request.newsItems.length}',
            animatedValue: true,
          ),
          _ContextLine(
            label: 'Screenshot',
            value: report.request.hasChartImage ? 'Included' : 'Not included',
          ),
          _ContextLine(
            label: 'User note',
            value: report.request.userNote == null ? 'Not included' : 'Included',
          ),
        ],
      ),
    );
  }
}

class _ContextLine extends StatelessWidget {
  const _ContextLine({
    required this.label,
    required this.value,
    this.animatedValue = false,
  });

  final String label;
  final String value;
  final bool animatedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.tiny),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.footnote)),
          if (animatedValue)
            AnimatedNumberText(
              value: value,
              style: AppTypography.caption1,
              stagger: const Duration(milliseconds: 12),
              duration: const Duration(milliseconds: 260),
              verticalOffset: 0.22,
              flipBegin: -0.08,
              scaleDown: true,
            )
          else
            Text(value, style: AppTypography.caption1),
        ],
      ),
    );
  }
}

class _AccentIcon extends StatelessWidget {
  const _AccentIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _ScenarioChip extends StatelessWidget {
  const _ScenarioChip({required this.scenario, this.showLabel = true});

  final MarketScenario scenario;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final label = _enumLabel(scenario.name);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        showLabel ? 'Scenario: $label' : label,
        style: AppTypography.caption1.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _RiskLevelChip extends StatelessWidget {
  const _RiskLevelChip({required this.riskLevel});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    final color = switch (riskLevel) {
      RiskLevel.low => AppColors.tradingUp,
      RiskLevel.medium => AppColors.warning,
      RiskLevel.high => AppColors.tradingDown,
      RiskLevel.unknown => AppColors.textTertiary,
    };

    return _MetricChip(
      label: 'Risk',
      value: _enumLabel(riskLevel.name),
      color: color,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.color = AppColors.textSecondary,
    this.animatedValue = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool animatedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.caption1.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (animatedValue)
            AnimatedNumberText(
              value: value,
              style: AppTypography.caption1.copyWith(
                color: AppColors.textPrimary,
              ),
              stagger: const Duration(milliseconds: 12),
              duration: const Duration(milliseconds: 260),
              verticalOffset: 0.22,
              flipBegin: -0.08,
              scaleDown: true,
            )
          else
            Text(
              value,
              style: AppTypography.caption1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Meta {
  const _Meta({required this.title, required this.icon, required this.color});

  final String title;
  final IconData icon;
  final Color color;

  static _Meta forRole(AnalystOutput output) {
    return switch (output.role) {
      AnalystRole.bull => const _Meta(
          title: 'Bull Expert',
          icon: CupertinoIcons.arrow_up_right,
          color: AppColors.tradingUp,
        ),
      AnalystRole.bear => const _Meta(
          title: 'Bear Expert',
          icon: CupertinoIcons.arrow_down_right,
          color: AppColors.tradingDown,
        ),
      AnalystRole.centrist => const _Meta(
          title: 'Centrist Expert',
          icon: CupertinoIcons.arrow_left_right,
          color: AppColors.info,
        ),
      AnalystRole.lead => const _Meta(
          title: 'Lead Analyst',
          icon: CupertinoIcons.checkmark_seal,
          color: AppColors.primaryPressed,
        ),
    };
  }
}

String _confidenceLabel(double confidence) {
  final normalized = confidence > 1 ? confidence / 100 : confidence;
  final clamped = normalized.clamp(0, 1).toDouble();
  return '${(clamped * 100).round()}%';
}

String _formatPrice(double value) {
  return '\$${value.toStringAsFixed(value.abs() >= 100 ? 2 : 3)}';
}

String _formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String _enumLabel(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
