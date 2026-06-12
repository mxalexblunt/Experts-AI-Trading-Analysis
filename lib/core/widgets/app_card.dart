import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'app_motion.dart';

enum AppCardStyle { elevated, hero, inset, listGroup, flat }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.all(AppSpacing.medium),
    this.useShadow,
    this.backgroundColor = AppColors.surface,
    this.style = AppCardStyle.elevated,
    this.radius,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final bool? useShadow;
  final Color backgroundColor;
  final AppCardStyle style;
  final double? radius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: _backgroundForStyle(style),
        borderRadius: BorderRadius.circular(radius ?? _radiusForStyle(style)),
        border: _borderForStyle(style),
        boxShadow: useShadow == false ? null : _shadowForStyle(style),
      ),
      child: child,
    );

    if (onPressed == null) {
      return content;
    }

    return MotionPressable(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        pressedOpacity: 1,
        onPressed: onPressed,
        child: content,
      ),
    );
  }

  Color _backgroundForStyle(AppCardStyle style) {
    return switch (style) {
      AppCardStyle.inset => backgroundColor == AppColors.surface
          ? AppColors.surfaceInset
          : backgroundColor,
      AppCardStyle.hero => backgroundColor == AppColors.surface
          ? AppColors.surfaceWash
          : backgroundColor,
      _ => backgroundColor,
    };
  }

  double _radiusForStyle(AppCardStyle style) {
    return switch (style) {
      AppCardStyle.hero => AppRadii.xxl,
      AppCardStyle.inset => AppRadii.lg,
      AppCardStyle.listGroup => AppRadii.xl,
      AppCardStyle.flat => AppRadii.lg,
      AppCardStyle.elevated => AppRadii.xl,
    };
  }

  Border? _borderForStyle(AppCardStyle style) {
    return switch (style) {
      AppCardStyle.inset || AppCardStyle.flat => Border.all(
          color: AppColors.border.withValues(alpha: 0.72),
        ),
      AppCardStyle.elevated || AppCardStyle.hero || AppCardStyle.listGroup =>
        null,
    };
  }

  List<BoxShadow>? _shadowForStyle(AppCardStyle style) {
    return switch (style) {
      AppCardStyle.hero => AppShadows.floating,
      AppCardStyle.elevated || AppCardStyle.listGroup => AppShadows.card,
      AppCardStyle.inset => AppShadows.subtle,
      AppCardStyle.flat => null,
    };
  }
}
