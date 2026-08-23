import 'package:flutter/services.dart';

/// A central utility for semantic haptic feedback.
class Haptics {
  /// Very light tap, used for minor selections like chips or toggles.
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Light impact, used for standard button presses.
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact, used for confirming destructive actions or heavy interactions.
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact, used for errors or significant alerts.
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }
}

