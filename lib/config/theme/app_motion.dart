import 'package:flutter/material.dart';

/// Standardized motion tokens and accessibility helpers for Serene Editorial.
abstract final class AppMotion {
  // === Durations ===
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration typewriter = Duration(milliseconds: 15);

  // === Curves ===
  static const Curve curveFast = Curves.easeOutCubic;
  static const Curve curveBase = Curves.easeInOutCubic;
  static const Curve curveSlow = Curves.easeOutQuart;

  // === Accessibility ===
  static bool shouldReduceMotion(BuildContext context) {
    try {
      return MediaQuery.maybeDisableAnimationsOf(context) ??
          WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    } catch (_) {
      return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    }
  }
}
