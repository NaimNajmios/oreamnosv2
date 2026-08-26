import 'package:flutter/material.dart';

import '../../domain/models/card_config.dart';

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

  static LinearGradient darkScrim(double opacity) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: opacity),
      ],
    );
  }

  static LinearGradient lightScrim(double opacity) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: opacity * 0.2),
        Colors.black.withValues(alpha: opacity * 0.5),
      ],
    );
  }

  static LinearGradient minimalScrim(double opacity) {
    return LinearGradient(
      begin: Alignment.center,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: opacity * 0.6),
      ],
    );
  }

  static LinearGradient horizontalScrim(double opacity) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.black.withValues(alpha: opacity),
        Colors.transparent,
      ],
    );
  }

  static LinearGradient reverseHorizontalScrim(double opacity) {
    return LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        Colors.black.withValues(alpha: opacity),
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
