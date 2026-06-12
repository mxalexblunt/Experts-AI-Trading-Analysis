import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 70);

  static const curve = Curves.easeOutCubic;
  static const pressedCurve = Curves.easeOut;
}

class MotionFadeSlide extends StatelessWidget {
  const MotionFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.medium,
    this.verticalOffset = 0.035,
    this.blur = false,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double verticalOffset;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final effects = <Effect<dynamic>>[
      FadeEffect(
        delay: delay,
        duration: duration,
        curve: AppMotion.curve,
        begin: 0,
        end: 1,
      ),
      SlideEffect(
        delay: delay,
        duration: duration,
        curve: AppMotion.curve,
        begin: Offset(0, verticalOffset),
        end: Offset.zero,
      ),
    ];

    if (blur) {
      effects.add(
        BlurEffect(
          delay: delay + const Duration(milliseconds: 80),
          duration: duration,
          curve: AppMotion.curve,
          begin: const Offset(6, 6),
          end: Offset.zero,
        ),
      );
    }

    return Animate(effects: effects, child: child);
  }
}

class MotionStaggeredColumn extends StatelessWidget {
  const MotionStaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.duration = AppMotion.medium,
    this.verticalOffset = 18,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Duration duration;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: AnimationConfiguration.toStaggeredList(
          duration: duration,
          childAnimationBuilder: (child) => SlideAnimation(
            verticalOffset: verticalOffset,
            child: FadeInAnimation(child: child),
          ),
          children: children,
        ),
      ),
    );
  }
}

class MotionStaggeredListItem extends StatelessWidget {
  const MotionStaggeredListItem({
    super.key,
    required this.position,
    required this.child,
    this.duration = AppMotion.medium,
    this.verticalOffset = 14,
  });

  final int position;
  final Widget child;
  final Duration duration;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: position,
      duration: duration,
      child: SlideAnimation(
        verticalOffset: verticalOffset,
        child: FadeInAnimation(child: child),
      ),
    );
  }
}

class MotionPressable extends StatefulWidget {
  const MotionPressable({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<MotionPressable> createState() => _MotionPressableState();
}

class _MotionPressableState extends State<MotionPressable> {
  bool _pressed = false;

  @override
  void didUpdateWidget(MotionPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) {
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: widget.enabled && _pressed ? 0.985 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.pressedCurve,
        child: AnimatedOpacity(
          opacity: widget.enabled && _pressed ? 0.86 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.pressedCurve,
          child: widget.child,
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }
}

class MotionLoadingIndicator extends StatelessWidget {
  const MotionLoadingIndicator({super.key, this.radius});

  final double? radius;

  @override
  Widget build(BuildContext context) {
    final indicator = radius == null
        ? const CupertinoActivityIndicator()
        : CupertinoActivityIndicator(radius: radius!);

    return MotionFadeSlide(
      blur: true,
      verticalOffset: 0.01,
      child: indicator,
    );
  }
}
