import 'package:flutter/material.dart';

/// Frames the card composition by softly darkening the outer perimeter.
class Vignette extends StatelessWidget {
  const Vignette({
    super.key,
    this.strength = 0.55,
    this.center = Alignment.center,
    this.radius = 0.95,
  });

  final double strength;
  final Alignment center;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: radius,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: strength),
              ],
              stops: const [0.0, 0.62, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
