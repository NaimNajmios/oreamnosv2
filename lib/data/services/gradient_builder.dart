import 'package:flutter/material.dart';

import '../../domain/models/card_config.dart';

/// Exact port of Android `GradientBuilder` scrim stop math.
class GradientBuilder {
  static LinearGradient vertical(List<Color> colors) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );
  }

  static LinearGradient diagonal(List<Color> colors) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  static RadialGradient radial(List<Color> colors) {
    return RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: colors,
    );
  }

  static LinearGradient darkScrim(double baseOpacity) {
    final o = baseOpacity;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.45, 0.65, 1.0],
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: (o * 0.8).clamp(0.0, 1.0)),
        Colors.black.withValues(alpha: (o * 1.5).clamp(0.0, 1.0)),
      ],
    );
  }

  static LinearGradient lightScrim(double baseOpacity) {
    final o = baseOpacity;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.6, 0.8, 1.0],
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: (o * 0.6).clamp(0.0, 1.0)),
        Colors.black.withValues(alpha: (o * 1.1).clamp(0.0, 1.0)),
      ],
    );
  }

  static LinearGradient minimalScrim(double baseOpacity) {
    final o = baseOpacity;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.7, 0.9, 1.0],
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: (o * 0.4).clamp(0.0, 1.0)),
        Colors.black.withValues(alpha: (o * 0.75).clamp(0.0, 1.0)),
      ],
    );
  }

  static LinearGradient horizontalScrim(double baseOpacity) {
    final o = baseOpacity;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.0, 0.5, 0.75, 1.0],
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: (o * 0.8).clamp(0.0, 1.0)),
        Colors.black.withValues(alpha: (o * 1.4).clamp(0.0, 1.0)),
      ],
    );
  }

  static LinearGradient reverseHorizontalScrim(double baseOpacity) {
    final o = baseOpacity;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.0, 0.25, 0.5, 1.0],
      colors: [
        Colors.black.withValues(alpha: (o * 1.4).clamp(0.0, 1.0)),
        Colors.black.withValues(alpha: (o * 0.8).clamp(0.0, 1.0)),
        Colors.transparent,
        Colors.transparent,
      ],
    );
  }

  static Gradient scrimFor(ScrimType type, double opacity) {
    switch (type) {
      case ScrimType.dark:
        return darkScrim(opacity);
      case ScrimType.light:
        return lightScrim(opacity);
      case ScrimType.minimal:
        return minimalScrim(opacity);
      case ScrimType.none:
        return const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        );
      case ScrimType.horizontal:
        return horizontalScrim(opacity);
      case ScrimType.reverseHorizontal:
        return reverseHorizontalScrim(opacity);
    }
  }
}
