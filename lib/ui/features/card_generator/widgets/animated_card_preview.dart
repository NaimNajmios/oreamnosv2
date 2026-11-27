import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Looping in-app motion preview for a card. Frame capture for export is
/// handled separately by [MotionExportService].
class AnimatedCardPreview extends StatelessWidget {
  const AnimatedCardPreview({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(begin: 0.6, end: 1, duration: duration),
        ScaleEffect(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: duration,
        ),
      ],
      autoPlay: true,
      onPlay: (controller) => controller.repeat(reverse: true),
      child: child,
    );
  }
}
