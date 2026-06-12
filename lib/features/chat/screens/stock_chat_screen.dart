import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_error.dart';
import '../../../core/services/stock_chat_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../providers/providers.dart';
import '../../settings/widgets/ai_consent_dialog.dart';

class StockChatScreen extends ConsumerStatefulWidget {
  const StockChatScreen({super.key});

  @override
  ConsumerState<StockChatScreen> createState() => _StockChatScreenState();
}

class _StockChatScreenState extends ConsumerState<StockChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<StockChatTurn> _messages = const [
    StockChatTurn(
      text:
          'Hi, I can help you think through stocks, ETFs, risk factors, and research questions in an educational way.',
      isUser: false,
    ),
  ].toList();

  bool _isSending = false;

  static const List<String> _quickPrompts = [
    'What should I check before analyzing AAPL?',
    'Compare SPY and QQQ risk factors.',
    'Explain earnings risk in simple terms.',
    'How do I research a dividend stock?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasConsent = ref.watch(settingsProvider).aiConsentGiven == true;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  CupertinoSliverNavigationBar(
                    largeTitle: const Text('AI Chat'),
                    middle: Text('AI Chat', style: AppTypography.headline),
                    alwaysShowMiddle: false,
                    backgroundColor: AppColors.canvas.withValues(alpha: 0.94),
                    border: null,
                    heroTag: 'stock_chat_sliver_navigation_bar',
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.large,
                      AppSpacing.screenPadding,
                      0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          if (!hasConsent) ...[
                            _ConsentCard(onGrant: _grantConsent),
                            const SizedBox(height: AppSpacing.medium),
                          ],
                          const _ChatBriefCard(),
                          const SizedBox(height: AppSpacing.medium),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _PromptRail(
                      prompts: _quickPrompts,
                      enabled: hasConsent && !_isSending,
                      onSelected: _sendPrompt,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.large,
                      AppSpacing.screenPadding,
                      AppSpacing.large,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          for (var i = 0; i < _messages.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.small,
                              ),
                              child: MotionStaggeredListItem(
                                position: i,
                                child: _MessageBubble(message: _messages[i]),
                              ),
                            ),
                          if (_isSending)
                            const Padding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.tiny,
                                bottom: AppSpacing.small,
                              ),
                              child: _TypingBubble(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Composer(
              controller: _controller,
              focusNode: _focusNode,
              enabled: hasConsent && !_isSending,
              isSending: _isSending,
              bottomInset: bottomInset,
              onSend: () => _sendPrompt(_controller.text),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grantConsent() async {
    final agreed = await showAiConsentDialog(context);
    await ref.read(settingsProvider.notifier).setAiConsent(agreed);
  }

  Future<void> _sendPrompt(String rawPrompt) async {
    final prompt = rawPrompt.trim();
    if (prompt.isEmpty || _isSending) return;

    if (ref.read(settingsProvider).aiConsentGiven != true) {
      await _grantConsent();
      if (ref.read(settingsProvider).aiConsentGiven != true) return;
    }

    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _messages.add(StockChatTurn(text: prompt, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final service = ref.read(stockChatAiServiceProvider);
      final reply = await service.ask(
        question: prompt,
        history: _messages,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(StockChatTurn(text: reply, isUser: false));
        _isSending = false;
      });
    } on AppError catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(StockChatTurn(text: error.message, isUser: false));
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const StockChatTurn(
            text: 'AI chat is temporarily unavailable. Please try again later.',
            isUser: false,
          ),
        );
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.medium,
        curve: AppMotion.curve,
      );
    });
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({required this.onGrant});

  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: const Icon(
                  CupertinoIcons.lock_shield,
                  color: AppColors.info,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI consent required', style: AppTypography.headline),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      'Enable AI data consent to send chat questions to Google Gemini.',
                      style: AppTypography.footnote,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          AppButton(
            label: 'Enable AI Consent',
            icon: CupertinoIcons.checkmark_shield,
            style: AppButtonStyle.secondary,
            onPressed: onGrant,
          ),
        ],
      ),
    );
  }
}

class _ChatBriefCard extends StatelessWidget {
  const _ChatBriefCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.hero,
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.subtle,
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: AppColors.ink,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Market discussion', style: AppTypography.title3),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Talk through tickers, ETFs, thesis checks, and risk questions.',
                  style: AppTypography.callout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptRail extends StatelessWidget {
  const _PromptRail({
    required this.prompts,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> prompts;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.tiny),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            pressedOpacity: 0.72,
            onPressed: enabled ? () => onSelected(prompt) : null,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
              ),
              decoration: BoxDecoration(
                color: enabled ? AppColors.surface : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.82),
                ),
              ),
              child: Center(
                child: Text(
                  prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.footnote.copyWith(
                    color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final StockChatTurn message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? AppColors.actionDark : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadii.lg),
              topRight: const Radius.circular(AppRadii.lg),
              bottomLeft: Radius.circular(isUser ? AppRadii.lg : AppRadii.xs),
              bottomRight: Radius.circular(isUser ? AppRadii.xs : AppRadii.lg),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: AppColors.border.withValues(alpha: 0.72),
                  ),
            boxShadow: isUser ? AppShadows.subtle : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: isUser
                ? Text(
                    message.text,
                    style: AppTypography.callout.copyWith(
                      color: AppColors.onActionDark,
                    ),
                  )
                : _MarkdownMessageText(text: message.text),
          ),
        ),
      ),
    );
  }
}

class _MarkdownMessageText extends StatelessWidget {
  const _MarkdownMessageText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.callout.copyWith(
      color: AppColors.textPrimary,
    );
    final footnote = AppTypography.footnote.copyWith(
      color: AppColors.textSecondary,
    );
    final codeStyle = AppTypography.footnote.copyWith(
      color: AppColors.textPrimary,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    );

    return MarkdownBody(
      data: text,
      selectable: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: base,
        pPadding: EdgeInsets.zero,
        strong: base.copyWith(fontWeight: FontWeight.w800),
        em: base.copyWith(fontStyle: FontStyle.italic),
        del: base.copyWith(decoration: TextDecoration.lineThrough),
        a: base.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w700,
        ),
        code: codeStyle,
        h1: AppTypography.title3,
        h1Padding: EdgeInsets.zero,
        h2: AppTypography.headline,
        h2Padding: EdgeInsets.zero,
        h3: AppTypography.headline,
        h3Padding: EdgeInsets.zero,
        h4: base.copyWith(fontWeight: FontWeight.w800),
        h4Padding: EdgeInsets.zero,
        h5: base.copyWith(fontWeight: FontWeight.w800),
        h5Padding: EdgeInsets.zero,
        h6: base.copyWith(fontWeight: FontWeight.w800),
        h6Padding: EdgeInsets.zero,
        blockSpacing: AppSpacing.tiny,
        listIndent: AppSpacing.large,
        listBullet: base,
        listBulletPadding: const EdgeInsets.only(right: AppSpacing.tiny),
        blockquote: footnote,
        blockquotePadding: const EdgeInsets.all(AppSpacing.small),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.surfaceInset,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.border),
        ),
        codeblockPadding: const EdgeInsets.all(AppSpacing.small),
        codeblockDecoration: BoxDecoration(
          color: AppColors.surfaceInset,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.border),
        ),
        tableHead: footnote.copyWith(fontWeight: FontWeight.w800),
        tableBody: footnote,
        tableCellsPadding: const EdgeInsets.all(AppSpacing.tiny),
        tableBorder: TableBorder.all(color: AppColors.border),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 72,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(radius: 10),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isSending,
    required this.bottomInset,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isSending;
  final double bottomInset;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = bottomInset > 0 ? AppSpacing.small : 128.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.72)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.small,
          AppSpacing.screenPadding,
          bottomPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                placeholder: 'Ask about a ticker, ETF, or market idea',
                placeholderStyle: AppTypography.callout.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                style: AppTypography.callout.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: BoxDecoration(
                  color: enabled ? AppColors.surface : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.86),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: AppSpacing.tiny),
            AppIconButton(
              icon: isSending ? CupertinoIcons.hourglass : CupertinoIcons.arrow_up,
              size: 48,
              iconSize: 22,
              backgroundColor: enabled ? AppColors.primary : AppColors.surfaceMuted,
              foregroundColor: enabled ? AppColors.onPrimary : AppColors.textDisabled,
              onPressed: enabled ? onSend : null,
            ),
          ],
        ),
      ),
    );
  }
}
