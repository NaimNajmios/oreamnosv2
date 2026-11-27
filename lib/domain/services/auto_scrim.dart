import 'package:flutter/material.dart';

/// Picks a scrim strength from the image palette so text keeps contrast.
abstract final class AutoScrim {
  static const double minOpacity = 0.25;
  static const double maxOpacity = 0.85;

  /// Brighter palettes need a darker scrim.
  static double opacityForPalette(
    List<Color> palette, {
    double min = minOpacity,
    double max = maxOpacity,
  }) {
    if (palette.isEmpty) return min;
    final average =
        palette.fold<double>(0, (sum, c) => sum + c.computeLuminance()) /
        palette.length;
    return (average * 1.4 + 0.15).clamp(min, max);
  }

  /// Never weakens the user's chosen scrim; only raises it when the sampled
  /// image is too bright for readable text.
  static double adjust(double userOpacity, List<Color>? palette) {
    if (palette == null || palette.isEmpty) return userOpacity;
    return userOpacity > opacityForPalette(palette)
        ? userOpacity
        : opacityForPalette(palette);
  }
}
