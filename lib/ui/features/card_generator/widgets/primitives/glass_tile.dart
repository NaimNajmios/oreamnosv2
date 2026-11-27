import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Frosted tile that blurs whatever is behind it on the card.
class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.child,
    this.blur = 8,
    this.opacity = 0.12,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}
