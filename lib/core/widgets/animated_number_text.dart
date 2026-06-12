import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedNumberText extends StatelessWidget {
  const AnimatedNumberText({
    super.key,
    required this.value,
    required this.style,
    this.stagger = const Duration(milliseconds: 24),
    this.duration = const Duration(milliseconds: 360),
    this.verticalOffset = 0.54,
    this.flipBegin = -0.24,
    this.scaleDown = false,
  });

  final String value;
  final TextStyle style;
  final Duration stagger;
  final Duration duration;
  final double verticalOffset;
  final double flipBegin;
  final bool scaleDown;

  @override
  Widget build(BuildContext context) {
    final characters = value.runes.map(String.fromCharCode).toList();

    final animatedText = Semantics(
      label: value,
      child: ExcludeSemantics(
        child: Row(
          key: ValueKey(value),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < characters.length; index++)
              Animate(
                key: ValueKey('$value-$index-${characters[index]}'),
                delay: Duration(milliseconds: stagger.inMilliseconds * index),
                effects: [
                  FadeEffect(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    begin: 0,
                    end: 1,
                  ),
                  SlideEffect(
                    duration: duration,
                    curve: Curves.easeOutBack,
                    begin: Offset(0, verticalOffset),
                    end: Offset.zero,
                  ),
                  FlipEffect(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    begin: flipBegin,
                    end: 0,
                    alignment: Alignment.bottomCenter,
                    perspective: 0.65,
                  ),
                  ScaleEffect(
                    duration: duration,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.94, 0.94),
                    end: const Offset(1, 1),
                    alignment: Alignment.bottomCenter,
                  ),
                ],
                child: Text(characters[index], style: style),
              ),
          ],
        ),
      ),
    );

    if (!scaleDown) return animatedText;

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: animatedText,
      ),
    );
  }
}
