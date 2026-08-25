import 'package:flutter/material.dart';

/// Spacing, radius, and layout tokens for the Minimalist flat design system.
abstract final class AppSpacing {
  // === 8pt Spacing Scale ===
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;

  // === Screen Padding & Constraints ===
  static const double screenHorizontal = 20.0;
  static const double maxContentWidth = 640.0;

  // === Corner Radii ===
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusPill = 999.0;

  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusPill = BorderRadius.all(Radius.circular(radiusPill));

  // === Subtle Flat Shadows ===
  static List<BoxShadow> subtleShadow(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> softShadow(bool isDark) => subtleShadow(isDark);

  static List<BoxShadow> elevatedShadow(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
