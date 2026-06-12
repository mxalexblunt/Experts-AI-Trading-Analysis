import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_motion.dart';

enum AppButtonStyle { primary, accent, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isInteractionDisabled = onPressed == null || isLoading;
    final isVisuallyDisabled = onPressed == null && !isLoading;
    final colors = _ButtonColors.forStyle(style, isVisuallyDisabled);

    if (style == AppButtonStyle.text) {
      return MotionPressable(
        enabled: !isInteractionDisabled,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          pressedOpacity: 1,
          onPressed: isInteractionDisabled ? null : onPressed,
          child: _ButtonContent(
            label: label,
            icon: icon,
            isLoading: isLoading,
            color: colors.foreground,
            fillWidthWhenLoading: false,
          ),
        ),
      );
    }

    return MotionPressable(
      enabled: !isInteractionDisabled,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        pressedOpacity: 1,
        onPressed: isInteractionDisabled ? null : onPressed,
        child: Container(
          height: style == AppButtonStyle.primary || style == AppButtonStyle.accent
              ? 54
              : 50,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: style == AppButtonStyle.secondary
                ? Border.all(color: AppColors.border.withValues(alpha: 0.65))
                : null,
            boxShadow: style == AppButtonStyle.primary ||
                    style == AppButtonStyle.accent
                ? AppShadows.control
                : null,
          ),
          child: Center(
            child: _ButtonContent(
              label: label,
              icon: icon,
              isLoading: isLoading,
              color: colors.foreground,
              fillWidthWhenLoading: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.color,
    required this.fillWidthWhenLoading,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color color;
  final bool fillWidthWhenLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final label = _LoadingButtonLabel(
        key: ValueKey(this.label),
        label: this.label,
        color: color,
        textAlign: fillWidthWhenLoading ? TextAlign.center : TextAlign.start,
      );

      return Semantics(
        label: this.label,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize:
                fillWidthWhenLoading ? MainAxisSize.max : MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoActivityIndicator(radius: 9, color: color),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              if (fillWidthWhenLoading)
                Expanded(child: _AnimatedLoadingButtonLabel(child: label))
              else
                _AnimatedLoadingButtonLabel(child: label),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.tiny),
        ],
        Text(label, style: AppTypography.button.copyWith(color: color)),
      ],
    );
  }
}

class _AnimatedLoadingButtonLabel extends StatelessWidget {
  const _AnimatedLoadingButtonLabel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      transitionBuilder: (child, animation) {
        final position = Tween<Offset>(
          begin: const Offset(0, 0.26),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppMotion.curve,
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: position, child: child),
        );
      },
      child: child,
    );
  }
}

class _LoadingButtonLabel extends StatelessWidget {
  const _LoadingButtonLabel({
    super.key,
    required this.label,
    required this.color,
    required this.textAlign,
  });

  final String label;
  final Color color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: AppTypography.button.copyWith(color: color),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          colors: [
            color.withValues(alpha: 0.48),
            AppColors.textPrimary,
            color.withValues(alpha: 0.48),
          ],
          stops: const [0.18, 0.5, 0.82],
          size: 0.7,
          angle: 0,
          blendMode: BlendMode.srcIn,
        );
  }
}

class _ButtonColors {
  const _ButtonColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static _ButtonColors forStyle(AppButtonStyle style, bool isDisabled) {
    if (isDisabled) {
      return const _ButtonColors(
        background: AppColors.surfaceMuted,
        foreground: AppColors.textDisabled,
      );
    }

    switch (style) {
      case AppButtonStyle.primary:
        return const _ButtonColors(
          background: AppColors.actionDark,
          foreground: AppColors.onActionDark,
        );
      case AppButtonStyle.accent:
        return const _ButtonColors(
          background: AppColors.primary,
          foreground: AppColors.onPrimary,
        );
      case AppButtonStyle.secondary:
        return const _ButtonColors(
          background: AppColors.surfaceSoft,
          foreground: AppColors.textPrimary,
        );
      case AppButtonStyle.text:
        return const _ButtonColors(
          background: CupertinoColors.transparent,
          foreground: AppColors.textPrimary,
        );
    }
  }
}
