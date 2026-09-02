import 'package:flutter/material.dart';

/// A subtle hairline divider that fades to transparent at both ends.
/// Replaces hard-edged 1dp strokes.
class FadeHairline extends StatelessWidget {
  const FadeHairline({
    super.key,
    this.opacity = 0.25,
    this.height = 1.5,
    this.color = Colors.white,
    this.margin,
  });

  final double opacity;
  final double height;
  final Color color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
