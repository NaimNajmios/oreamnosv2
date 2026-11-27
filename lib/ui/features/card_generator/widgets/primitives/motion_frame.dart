import 'package:flutter/material.dart';

/// One deterministic motion frame: a subtle scale/fade applied to a card.
class MotionFrame extends StatelessWidget {
  const MotionFrame({super.key, required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Opacity(
      opacity: 0.7 + 0.3 * p,
      child: Transform.scale(
        scale: 0.96 + 0.04 * p,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
