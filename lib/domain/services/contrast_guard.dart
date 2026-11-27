import 'package:flutter/material.dart';

/// WCAG contrast checks for text drawn over card surfaces.
abstract final class ContrastGuard {
  static const double minimumTextContrast = 4.5;

  static double ratio(Color foreground, Color background) {
    final a = foreground.computeLuminance();
    final b = background.computeLuminance();
    final light = a > b ? a : b;
    final dark = a > b ? b : a;
    return (light + 0.05) / (dark + 0.05);
  }

  static bool isReadable(
    Color foreground,
    Color background, {
    double minimum = minimumTextContrast,
  }) => ratio(foreground, background) >= minimum;
}
