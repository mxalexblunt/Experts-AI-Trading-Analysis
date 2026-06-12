import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_number_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/asset_logo_tile.dart';
import '../../../core/widgets/app_motion.dart';
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
    final currentReport = reportState.valueOrNull;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.canvas,
        middle: kDebugMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                pressedOpacity: 0.62,
                onPressed: () {
                  final report = ref
                      .read(marketAnalysisProvider.notifier)
                      .showNextDebugReport();
                  ref
                      .read(analysisDraftProvider.notifier)
                      .startFromAsset(report.asset);
                },
                child: Text('AI Report', style: AppTypography.headline),
              )
            : Text('AI Report', style: AppTypography.headline),
        trailing: currentReport == null
            ? null
            : _ReportNavActions(report: currentReport),
      ),
      child: SafeArea(
        top: false,
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

class _ReportNavActions extends StatelessWidget {
  const _ReportNavActions({required this.report});

  final MarketAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavGlyphButton(
          icon: CupertinoIcons.square_arrow_up,
          onPressed: () => _showReportMenu(context, report),
        ),
        const SizedBox(width: AppSpacing.micro),
        _NavGlyphButton(
          icon: CupertinoIcons.ellipsis_circle,
          onPressed: () => _showReportMenu(context, report),
        ),
      ],
    );
  }
}

class _NavGlyphButton extends StatelessWidget {
  const _NavGlyphButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(AppSpacing.micro),
      minimumSize: Size.zero,
      pressedOpacity: 0.62,
      onPressed: onPressed,
      child: Icon(icon, color: AppColors.textPrimary, size: 24),
    );
  }
}

void _showReportMenu(BuildContext context, MarketAnalysisReport report) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) {
      return CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _copyReportSummary(report);
            },
            child: const Text('Copy Summary'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _copyReportRisks(report);
            },
            child: const Text('Copy Risks'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      );
    },
  );
}

void _copyReportSummary(MarketAnalysisReport report) {
  Clipboard.setData(
    ClipboardData(
      text: [
        '${report.asset.symbol} AI Report',
        report.finalSummary,
        'Scenario: ${_enumLabel(report.scenario.name)}',
        'Risk: ${_enumLabel(report.leadConclusion.riskLevel.name)}',
      ].join('\n'),
    ),
  );
}

void _copyReportRisks(MarketAnalysisReport report) {
  final risks = report.keyRisks.isNotEmpty
      ? report.keyRisks
      : report.leadConclusion.keyRisks;
  Clipboard.setData(
    ClipboardData(
      text: risks.isEmpty ? 'No key risks returned.' : risks.join('\n'),
    ),
  );
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
  void didUpdateWidget(covariant _ReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.id != widget.report.id) {
      _selectedTab = _ReportTab.lead;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.small,
        AppSpacing.screenPadding,
        80,
      ),
      children: [
        MotionStaggeredColumn(
          children: [
            _MarketHeroCard(report: report),
            const SizedBox(height: AppSpacing.medium),
            _RoleSelector(
              selectedTab: _selectedTab,
              onChanged: (value) => setState(() => _selectedTab = value),
            ),
            const SizedBox(height: AppSpacing.medium),
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
            if (report.isFallback) ...[
              const SizedBox(height: AppSpacing.medium),
              _FallbackNotice(report: report),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.micro),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CupertinoSlidingSegmentedControl<_ReportTab>(
        groupValue: selectedTab,
        backgroundColor: AppColors.canvas,
        thumbColor: AppColors.primary,
        padding: EdgeInsets.zero,
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
        children: {
          for (final tab in _ReportTab.values)
            tab: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.micro,
                vertical: 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab == selectedTab) ...[
                    Icon(_tabIcon(tab), size: 14, color: AppColors.textPrimary),
                    const SizedBox(width: AppSpacing.micro),
                  ],
                  Flexible(
                    child: Text(
                      _tabLabel(tab),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption1.copyWith(
                        color: tab == selectedTab
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            tab == selectedTab ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        },
      ),
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
    final risks = isLead && report.keyRisks.isNotEmpty
        ? report.keyRisks
        : output.keyRisks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VerdictPanel(report: report, tab: tab, output: output),
        const SizedBox(height: AppSpacing.medium),
        if (isLead)
          _ExpertDeskSection(report: report, risks: risks)
        else
          _AnalystFocusPanel(tab: tab, output: output),
        if (!isLead && risks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          _RiskWatchTray(risks: risks),
        ],
        const SizedBox(height: AppSpacing.medium),
        _ContextRail(report: report),
      ],
    );
  }
}

class _VerdictPanel extends StatelessWidget {
  const _VerdictPanel({
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
    final scenario = tab == _ReportTab.lead ? report.scenario : output.scenario;

    return _PremiumPanel(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlowIcon(icon: meta.icon, color: meta.color, size: 30),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  tab == _ReportTab.lead
                      ? 'Lead Analyst Conclusion'
                      : meta.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headline,
                ),
              ),
              _ScenarioPill(scenario: scenario),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(_verdictTitle(scenario, tab), style: AppTypography.title3),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.subhead,
          ),
          const SizedBox(height: AppSpacing.small),
          _MetricBoard(
            riskLevel: output.riskLevel,
            confidence: output.confidence,
            scenario: scenario,
          ),
          const SizedBox(height: AppSpacing.small),
          _EvidenceSection(output: output, tab: tab),
        ],
      ),
    );
  }
}

class _MetricBoard extends StatelessWidget {
  const _MetricBoard({
    required this.riskLevel,
    required this.confidence,
    required this.scenario,
  });

  final RiskLevel riskLevel;
  final double? confidence;
  final MarketScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      decoration: BoxDecoration(
        color: AppColors.canvasPure.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.68)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _GaugeMetric(
                label: 'Risk Level',
                value: _enumLabel(riskLevel.name),
                color: _riskColor(riskLevel),
                progress: _riskProgress(riskLevel),
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _RingMetric(
                label: 'Confidence',
                value: confidence == null ? 0.0 : _confidenceValue(confidence!),
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _ScenarioMetric(scenario: scenario),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugeMetric extends StatelessWidget {
  const _GaugeMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  final String label;
  final String value;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tiny,
        vertical: AppSpacing.tiny,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTypography.caption2),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.callout.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          SizedBox(
            height: 24,
            width: 66,
            child: CustomPaint(
              painter: _GaugePainter(progress: progress, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingMetric extends StatelessWidget {
  const _RingMetric({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tiny,
        vertical: AppSpacing.tiny,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTypography.caption2),
          const SizedBox(height: AppSpacing.micro),
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(44),
                  painter: _RingPainter(progress: value, strokeWidth: 5),
                ),
                AnimatedNumberText(
                  value: percent,
                  style: AppTypography.callout.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  stagger: const Duration(milliseconds: 10),
                  duration: const Duration(milliseconds: 260),
                  verticalOffset: 0.2,
                  flipBegin: -0.08,
                  scaleDown: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioMetric extends StatelessWidget {
  const _ScenarioMetric({required this.scenario});

  final MarketScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tiny,
        vertical: AppSpacing.tiny,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Scenario', style: AppTypography.caption2),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            _enumLabel(scenario.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.callout.copyWith(
              color: _scenarioColor(scenario),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Icon(_scenarioIcon(scenario), color: _scenarioColor(scenario), size: 24),
        ],
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.output, required this.tab});

  final AnalystOutput output;
  final _ReportTab tab;

  @override
  Widget build(BuildContext context) {
    final points = output.points.take(3).toList(growable: false);
    if (points.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: AppColors.canvasPure.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.58)),
        ),
        child: Text(
          'No separate evidence points returned.',
          style: AppTypography.footnote.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Key Evidence', style: AppTypography.headline),
            const Spacer(),
            Text(
              'View all',
              style: AppTypography.caption1.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        for (var index = 0; index < points.length; index++) ...[
          _EvidenceRow(
            index: index,
            text: points[index],
            tab: tab,
            confidence: output.confidence,
          ),
          if (index != points.length - 1) const SizedBox(height: AppSpacing.tiny),
        ],
      ],
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.index,
    required this.text,
    required this.tab,
    required this.confidence,
  });

  final int index;
  final String text;
  final _ReportTab tab;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    final color = _evidenceColor(tab, index);
    final strength = _evidenceStrength(confidence, index);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvasPure.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.58)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SignalIcon(icon: _evidenceIcon(tab, index), color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.footnote.copyWith(
                color: AppColors.textPrimary,
                height: 1.24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _StrengthMeter(
            label: _strengthLabel(strength),
            value: strength,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Row(
            children: [
              for (var index = 0; index < 5; index++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: index == 4 ? 0 : 3),
                    decoration: BoxDecoration(
                      color: index < (value * 5).round()
                          ? color
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpertDeskSection extends StatelessWidget {
  const _ExpertDeskSection({required this.report, required this.risks});

  final MarketAnalysisReport report;
  final List<String> risks;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expert Desk', style: AppTypography.headline),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(child: _ExpertTile(output: report.bullCase)),
              const SizedBox(width: AppSpacing.tiny),
              Expanded(child: _ExpertTile(output: report.bearCase)),
              const SizedBox(width: AppSpacing.tiny),
              Expanded(child: _ExpertTile(output: report.centristCase)),
            ],
          ),
          if (risks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            _RiskWatchTray(risks: risks, compact: true),
          ],
        ],
      ),
    );
  }
}

class _ExpertTile extends StatelessWidget {
  const _ExpertTile({required this.output});

  final AnalystOutput output;

  @override
  Widget build(BuildContext context) {
    final meta = _Meta.forRole(output);
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(AppSpacing.tiny),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: meta.color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SignalIcon(icon: meta.icon, color: meta.color, size: 28),
              const SizedBox(width: AppSpacing.tiny),
              Expanded(
                child: Text(
                  meta.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.tiny),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confidence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (output.confidence != null)
                _MiniRing(value: _confidenceValue(output.confidence!), size: 34),
            ],
          ),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            output.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2.copyWith(
              color: AppColors.textSecondary,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  const _MiniRing({required this.value, this.size = 40});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: value, strokeWidth: 4),
          ),
          Text(
            '${(value * 100).round()}%',
            style: AppTypography.caption2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalystFocusPanel extends StatelessWidget {
  const _AnalystFocusPanel({required this.tab, required this.output});

  final _ReportTab tab;
  final AnalystOutput output;

  @override
  Widget build(BuildContext context) {
    final meta = _Meta.forRole(output);
    return _PremiumPanel(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlowIcon(icon: CupertinoIcons.lightbulb, color: meta.color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analyst Focus', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.micro),
                Text(_roleFocus(tab), style: AppTypography.callout),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskWatchTray extends StatelessWidget {
  const _RiskWatchTray({required this.risks, this.compact = false});

  final List<String> risks;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visibleRisks = risks.take(3).toList(growable: false);
    final compactRisks = visibleRisks.take(2).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.small : AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SignalIcon(
            icon: CupertinoIcons.exclamationmark_triangle,
            color: AppColors.warning,
            size: compact ? 32 : 38,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: compact
                ? Row(
                    children: [
                      SizedBox(
                        width: 86,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Risk Watch', style: AppTypography.headline),
                            const SizedBox(height: AppSpacing.micro),
                            Text(
                              'Key risks to monitor',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Row(
                          children: [
                            for (var index = 0;
                                index < compactRisks.length;
                                index++) ...[
                              Expanded(
                                child: _RiskSnippet(text: compactRisks[index]),
                              ),
                              if (index != compactRisks.length - 1)
                                const SizedBox(width: AppSpacing.tiny),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Risk Watch', style: AppTypography.headline),
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        visibleRisks.join('  •  '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.callout.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.tiny),
            const Icon(CupertinoIcons.chevron_right, color: AppColors.warning),
          ],
        ],
      ),
    );
  }
}

class _RiskSnippet extends StatelessWidget {
  const _RiskSnippet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tiny,
        vertical: AppSpacing.micro,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvasPure.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.slider_horizontal_3,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextRail extends StatelessWidget {
  const _ContextRail({required this.report});

  final MarketAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.info_circle, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.tiny),
              Text('Context Snapshot', style: AppTypography.headline),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(
                child: _ContextCell(
                  icon: CupertinoIcons.calendar,
                  label: 'Timeframe',
                  value: report.request.timeframe,
                ),
              ),
              const SizedBox(width: AppSpacing.micro),
              Expanded(
                child: _ContextCell(
                  icon: CupertinoIcons.chart_bar,
                  label: 'Points',
                  value: '${report.request.chartPoints.length}',
                  animatedValue: true,
                ),
              ),
              const SizedBox(width: AppSpacing.micro),
              Expanded(
                child: _ContextCell(
                  icon: CupertinoIcons.doc_text,
                  label: 'News',
                  value: '${report.request.newsItems.length}',
                  animatedValue: true,
                ),
              ),
              const SizedBox(width: AppSpacing.micro),
              Expanded(
                child: _ContextCell(
                  icon: CupertinoIcons.photo,
                  label: 'Image',
                  value: report.request.hasChartImage ? 'Yes' : 'No',
                ),
              ),
              const SizedBox(width: AppSpacing.micro),
              Expanded(
                child: _ContextCell(
                  icon: CupertinoIcons.text_bubble,
                  label: 'Note',
                  value: report.request.userNote == null ? 'No' : 'Yes',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'Generated ${_dateTimeLabel(report.createdAt)}  •  ${report.disclaimer}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.caption1.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ContextCell extends StatelessWidget {
  const _ContextCell({
    required this.icon,
    required this.label,
    required this.value,
    this.animatedValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool animatedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.micro,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvasPure.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.58)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(height: AppSpacing.micro),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2,
          ),
          const SizedBox(height: 2),
          if (animatedValue)
            AnimatedNumberText(
              value: value,
              style: AppTypography.caption1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.report});

  final MarketAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return AppStatusCard(
      icon: CupertinoIcons.exclamationmark_triangle,
      title: 'Partial AI fallback',
      message: _fallbackMessage(report),
      color: AppColors.warning,
    );
  }
}

class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.medium),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.58)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SignalIcon extends StatelessWidget {
  const _SignalIcon({
    required this.icon,
    required this.color,
    this.size = 36,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({
    required this.icon,
    required this.color,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: size * 0.54),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      color: AppColors.divider,
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 8, size.width - 12, size.height * 1.6);
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = AppColors.surfaceMuted;
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = color;
    canvas.drawArc(rect, math.pi, math.pi, false, backgroundPaint);
    canvas.drawArc(rect, math.pi, math.pi * progress.clamp(0, 1), false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, this.strokeWidth = 6});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final insetRect = rect.deflate(strokeWidth / 2);
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = AppColors.surfaceMuted;
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = AppColors.primaryPressed;
    canvas.drawCircle(rect.center, insetRect.width / 2, backgroundPaint);
    canvas.drawArc(
      insetRect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _ScenarioPill extends StatelessWidget {
  const _ScenarioPill({required this.scenario});

  final MarketScenario scenario;

  @override
  Widget build(BuildContext context) {
    final color = _scenarioColor(scenario);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        _enumLabel(scenario.name),
        style: AppTypography.caption1.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
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

class _MarketHeroCard extends StatelessWidget {
  const _MarketHeroCard({required this.report});

  final MarketAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final price = report.asset.currentPrice == null
        ? 'Unavailable'
        : _formatPrice(report.asset.currentPrice!);
    final change = _formatChangeLabel(
      change: report.asset.change,
      changePercent: report.asset.changePercent,
    );
    final changeColor = (report.asset.changePercent ?? 0) >= 0
        ? AppColors.tradingUp
        : AppColors.tradingDown;
    final range = _chartRange(report.request.chartPoints);
    final latestVolume = _latestVolume(report.request.chartPoints);

    return _PremiumPanel(
      padding: const EdgeInsets.all(AppSpacing.small),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssetLogoTile(
                symbol: report.asset.symbol,
                type: report.asset.type,
                logoUrl: report.asset.logoUrl,
                size: 48,
                showChartFallback: true,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.asset.symbol, style: AppTypography.title3),
                    const SizedBox(height: AppSpacing.micro),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.asset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.tiny),
                        _ExchangePill(label: _exchangeLabel(report.asset)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              SizedBox(
                width: 128,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTypography.title3,
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      change,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTypography.subhead.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.tiny),
          SizedBox(
            height: 58,
            child: Stack(
              children: [
                Positioned.fill(
                  top: AppSpacing.small,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      points: report.request.chartPoints,
                      color: changeColor,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _TimeframeStrip(selected: report.request.timeframe),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'High',
                  value: range.high == null ? 'N/A' : _formatPrice(range.high!),
                ),
              ),
              Expanded(
                child: _HeaderMetric(
                  label: 'Low',
                  value: range.low == null ? 'N/A' : _formatPrice(range.low!),
                ),
              ),
              Expanded(
                child: _HeaderMetric(
                  label: 'Signals',
                  value: '${report.request.newsItems.length}',
                  animatedValue: true,
                ),
              ),
              Expanded(
                child: _HeaderMetric(
                  label: 'Volume',
                  value: latestVolume == null ? 'N/A' : _formatCompactNumber(latestVolume),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeframeStrip extends StatelessWidget {
  const _TimeframeStrip({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    const labels = ['1D', '1W', '1M', '3M', '1Y'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final label in labels)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.micro),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.tiny,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: label == selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                label,
                style: AppTypography.caption2.copyWith(
                  color: label == selected
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontWeight: label == selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExchangePill extends StatelessWidget {
  const _ExchangePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tiny,
        vertical: AppSpacing.micro,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption2.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    this.animatedValue = false,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool animatedValue;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption2),
        const SizedBox(height: AppSpacing.micro),
        if (animatedValue)
          AnimatedNumberText(
            value: value,
            style: AppTypography.caption1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.points, required this.color});

  final List<ChartPointModel> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((point) => point.close).toList(growable: false);
    if (values.length < 2) {
      final paint = Paint()
        ..color = AppColors.surfaceMuted
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 0.01);
    final path = Path();
    final fillPath = Path();

    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? 0.0
          : size.width * index / (values.length - 1);
      final y = size.height - ((values[index] - minValue) / range) * size.height;
      final point = Offset(x, y.clamp(4.0, size.height - 4));
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, size.height);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.4
      ..color = color;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);

    final gridPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _ChartRange {
  const _ChartRange({required this.high, required this.low});

  final double? high;
  final double? low;
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

IconData _tabIcon(_ReportTab tab) {
  return switch (tab) {
    _ReportTab.lead => CupertinoIcons.star,
    _ReportTab.bull => CupertinoIcons.arrow_up_right,
    _ReportTab.bear => CupertinoIcons.arrow_down_right,
    _ReportTab.centrist => CupertinoIcons.arrow_left_right,
  };
}

String _verdictTitle(MarketScenario scenario, _ReportTab tab) {
  if (tab != _ReportTab.lead) {
    return switch (tab) {
      _ReportTab.bull => 'Bull case',
      _ReportTab.bear => 'Bear case',
      _ReportTab.centrist => 'Balanced case',
      _ReportTab.lead => 'Lead verdict',
    };
  }
  return switch (scenario) {
    MarketScenario.bullish => 'Bullish outlook',
    MarketScenario.bearish => 'Bearish outlook',
    MarketScenario.neutral => 'Neutral outlook',
    MarketScenario.mixed => 'Mixed outlook',
    MarketScenario.unknown => 'Lead verdict',
  };
}

Color _riskColor(RiskLevel riskLevel) {
  return switch (riskLevel) {
    RiskLevel.low => AppColors.tradingUp,
    RiskLevel.medium => AppColors.warning,
    RiskLevel.high => AppColors.tradingDown,
    RiskLevel.unknown => AppColors.textTertiary,
  };
}

double _riskProgress(RiskLevel riskLevel) {
  return switch (riskLevel) {
    RiskLevel.low => 0.34,
    RiskLevel.medium => 0.62,
    RiskLevel.high => 0.9,
    RiskLevel.unknown => 0.2,
  };
}

Color _scenarioColor(MarketScenario scenario) {
  return switch (scenario) {
    MarketScenario.bullish => AppColors.tradingUp,
    MarketScenario.bearish => AppColors.tradingDown,
    MarketScenario.neutral => AppColors.info,
    MarketScenario.mixed => AppColors.warning,
    MarketScenario.unknown => AppColors.textTertiary,
  };
}

IconData _scenarioIcon(MarketScenario scenario) {
  return switch (scenario) {
    MarketScenario.bullish => CupertinoIcons.arrow_up_right,
    MarketScenario.bearish => CupertinoIcons.arrow_down_right,
    MarketScenario.neutral => CupertinoIcons.minus,
    MarketScenario.mixed => CupertinoIcons.arrow_left_right,
    MarketScenario.unknown => CupertinoIcons.question,
  };
}

Color _evidenceColor(_ReportTab tab, int index) {
  if (tab == _ReportTab.bull) return AppColors.tradingUp;
  if (tab == _ReportTab.bear) return AppColors.tradingDown;
  if (tab == _ReportTab.centrist) return AppColors.info;
  return switch (index) {
    0 => AppColors.tradingUp,
    1 => AppColors.warning,
    _ => AppColors.info,
  };
}

IconData _evidenceIcon(_ReportTab tab, int index) {
  if (tab == _ReportTab.bull) return CupertinoIcons.arrow_up_right;
  if (tab == _ReportTab.bear) return CupertinoIcons.arrow_down_right;
  if (tab == _ReportTab.centrist) return CupertinoIcons.arrow_left_right;
  return switch (index) {
    0 => CupertinoIcons.arrow_up_right,
    1 => CupertinoIcons.exclamationmark_triangle,
    _ => CupertinoIcons.chart_bar,
  };
}

double _evidenceStrength(double? confidence, int index) {
  final base = confidence == null ? 0.56 : _confidenceValue(confidence);
  final adjusted = base - (index * 0.08);
  return adjusted.clamp(0.28, 0.92).toDouble();
}

String _strengthLabel(double value) {
  if (value >= 0.72) return 'Strong';
  if (value >= 0.48) return 'Moderate';
  return 'Limited';
}

double _confidenceValue(double confidence) {
  final normalized = confidence > 1 ? confidence / 100 : confidence;
  return normalized.clamp(0, 1).toDouble();
}

_ChartRange _chartRange(List<ChartPointModel> points) {
  if (points.isEmpty) return const _ChartRange(high: null, low: null);
  final highs = points.map((point) => point.high ?? point.close);
  final lows = points.map((point) => point.low ?? point.close);
  return _ChartRange(
    high: highs.reduce(math.max),
    low: lows.reduce(math.min),
  );
}

double? _latestVolume(List<ChartPointModel> points) {
  for (final point in points.reversed) {
    if (point.volume != null) return point.volume;
  }
  return null;
}

String _compactDateLabel(DateTime date) {
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
  final month = months[date.month - 1];
  return '$month ${date.day}';
}

String _dateTimeLabel(DateTime date) {
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final meridiem = date.hour >= 12 ? 'PM' : 'AM';
  return '${_compactDateLabel(date)}, ${date.year} at $hour:$minute $meridiem';
}

String _exchangeLabel(AssetModel asset) {
  final exchange = asset.exchange?.trim();
  if (exchange != null && exchange.isNotEmpty) return exchange.toUpperCase();
  return asset.type.name.toUpperCase();
}

String _formatPrice(double value) {
  return value.toStringAsFixed(value.abs() >= 100 ? 2 : 3);
}

String _formatChangeLabel({
  required double? change,
  required double? changePercent,
}) {
  if (change == null && changePercent == null) return 'Unavailable';
  final parts = <String>[];
  if (change != null) {
    parts.add(_formatSignedNumber(change));
  }
  if (changePercent != null) {
    final formattedPercent = _formatPercent(changePercent);
    parts.add(change == null ? formattedPercent : '($formattedPercent)');
  }
  final indicatorValue = changePercent ?? change ?? 0;
  final arrow = indicatorValue >= 0 ? '▲' : '▼';
  return '${parts.join(' ')} $arrow';
}

String _formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String _formatSignedNumber(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(value.abs() >= 100 ? 2 : 3)}';
}

String _formatCompactNumber(double value) {
  final abs = value.abs();
  if (abs >= 1000000000000) return '${(value / 1000000000000).toStringAsFixed(1)}T';
  if (abs >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}

String _enumLabel(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
