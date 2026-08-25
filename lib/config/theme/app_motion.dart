import 'package:flutter/material.dart';

/// Standardized motion tokens and accessibility helpers from the Sciuro design system.
abstract final class AppMotion {
  // === Sciuro Named Motion Specs ===
  /// micro: 120ms, fast-out-slow-in — Small state changes (toggle flipping, checkbox)
  static const Duration micro = Duration(milliseconds: 120);

  /// transitionSpec: 280ms, fast-out-slow-in — Screen-level transitions & sheets
  static const Duration transitionSpec = Duration(milliseconds: 280);

  /// count: 500ms, linear-out-slow-in — Numeric counters & value changes
  static const Duration count = Duration(milliseconds: 500);

  /// cardMove: spring duration for reordering & canvas shuffling
  static const Duration cardMove = Duration(milliseconds: 320);

  /// celebration: spring duration for success milestones
  static const Duration celebration = Duration(milliseconds: 600);

  // === Legacy aliases for backward compatibility ===
  static const Duration fast = micro;
  static const Duration base = transitionSpec;
  static const Duration slow = count;
  static const Duration typewriter = Duration(milliseconds: 15);
  static const Duration particle = Duration(milliseconds: 400);
  static const Duration shimmy = Duration(milliseconds: 800);
  static const Duration breathing = Duration(milliseconds: 1200);

  // === Sciuro Named Curves ===
  static const Curve curveMicro = Curves.fastOutSlowIn;
  static const Curve curveTransition = Curves.fastOutSlowIn;
  static const Curve curveCount = Curves.easeOutCubic;
  static const Curve curveCardMove = Cubic(0.34, 1.4, 0.64, 1.0);
  static const Curve curveCelebration = Cubic(0.2, 1.1, 0.4, 1.0);

  static const Curve curveFast = Curves.easeOutCubic;
  static const Curve curveBase = Curves.easeInOutCubic;
  static const Curve curveSlow = Curves.easeOutQuart;
  static const Curve springMediumBouncy = Cubic(0.34, 1.56, 0.64, 1.0);

  // === Accessibility ===
  /// Centralized check for OS-level 'Reduce Motion' / disableAnimations setting.
  static bool shouldReduceMotion(BuildContext context) {
    try {
      return MediaQuery.maybeDisableAnimationsOf(context) ??
          WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    } catch (_) {
      return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    }
  }
}

