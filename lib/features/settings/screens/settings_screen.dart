import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_divider.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../doc_viewer.dart';
import '../../report/screens/ai_report_screen.dart';
import '../../../providers/providers.dart';
import '../widgets/ai_consent_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _privacyPolicyUrl =
      'https://expertsanalysisapp.web.app/privacy';
  static const String _termsOfUseUrl =
      'https://expertsanalysisapp.web.app/terms';
  static const String _supportFormUrl =
      'https://expertsanalysisapp.web.app/support';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final consentValue = settings.aiConsentGiven == true;
    final isFinnhubConfigured = ref.watch(finnhubRepositoryProvider).isConfigured;
    final isTwelveDataConfigured =
        ref.watch(twelveDataChartRepositoryProvider).isConfigured;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Settings'),
            middle: Text('Settings', style: AppTypography.headline),
            alwaysShowMiddle: false,
            backgroundColor: AppColors.canvas.withValues(alpha: 0.94),
            border: null,
            heroTag: 'settings_sliver_navigation_bar',
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
                  const AppSectionHeader(title: 'AI Privacy'),
                  const SizedBox(height: AppSpacing.small),
                  _SettingsGroup(
                    children: [
                      _SwitchRow(
                        title: 'AI Data Consent',
                        subtitle: _consentSubtitle(settings.aiConsentGiven),
                        value: consentValue,
                        onChanged: (value) => _changeConsent(context, ref, value),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xlarge),
                  const AppSectionHeader(title: 'Data Sources'),
                  const SizedBox(height: AppSpacing.small),
                  _SettingsGroup(
                    children: [
                      _SettingsRow(
                        title: 'Market Data',
                        subtitle: 'Finnhub powers search, quotes, and news.',
                        value: isFinnhubConfigured ? 'Connected' : 'Pending key',
                      ),
                      _SettingsRow(
                        title: 'Chart Data',
                        subtitle: 'Twelve Data powers chart history.',
                        value:
                            isTwelveDataConfigured ? 'Connected' : 'Pending key',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xlarge),
                  if (kDebugMode) ...[
                    const AppSectionHeader(title: 'Debug'),
                    const SizedBox(height: AppSpacing.small),
                    _SettingsGroup(
                      children: [
                        _DocumentRow(
                          title: 'Show Test AI Report',
                          onPressed: () => _showTestAiReport(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xlarge),
                  ],
                  const AppSectionHeader(title: 'Legal'),
                  const SizedBox(height: AppSpacing.small),
                  _SettingsGroup(
                    children: [
                      _DocumentRow(
                        title: 'Privacy Policy',
                        onPressed: () => docViewer(
                          context,
                          _privacyPolicyUrl,
                          'Privacy Policy',
                        ),
                      ),
                      _DocumentRow(
                        title: 'Terms of Use',
                        onPressed: () => docViewer(
                          context,
                          _termsOfUseUrl,
                          'Terms of Use',
                        ),
                      ),
                      _DocumentRow(
                        title: 'Support Form',
                        onPressed: () => docViewer(
                          context,
                          _supportFormUrl,
                          'Support Form',
                        ),
                      ),
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

  String _consentSubtitle(bool? value) {
    if (value == true) {
      return 'You agreed to send analysis context to Gemini.';
    }
    if (value == false) {
      return 'AI features are disabled until you grant consent again.';
    }
    return 'You will be asked before the first AI analysis.';
  }

  Future<void> _changeConsent(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (value) {
      final agreed = await showAiConsentDialog(context);
      await ref.read(settingsProvider.notifier).setAiConsent(agreed);
      return;
    }

    final revoke = await showRevokeAiConsentDialog(context);
    if (revoke) {
      await ref.read(settingsProvider.notifier).setAiConsent(false);
    }
  }

  void _showTestAiReport(BuildContext context, WidgetRef ref) {
    final report = ref.read(marketAnalysisProvider.notifier).showDebugReport();
    ref.read(analysisDraftProvider.notifier).startFromAsset(report.asset);
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        settings: const RouteSettings(name: 'AiReportScreen.debug'),
        builder: (_) => AiReportScreen(asset: report.asset),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      style: AppCardStyle.listGroup,
      child: MotionStaggeredColumn(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                child: AppDivider(),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline),
                const SizedBox(height: AppSpacing.micro),
                Text(subtitle, style: AppTypography.footnote),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          _StatusPill(value: value),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final isConnected = value == 'Connected';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.tradingUp.withValues(alpha: 0.12) : AppColors.surfaceInset,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: AppTypography.caption1.copyWith(
          color: isConnected ? AppColors.tradingUp : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.72,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.headline,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline),
                const SizedBox(height: AppSpacing.micro),
                Text(subtitle, style: AppTypography.footnote),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
