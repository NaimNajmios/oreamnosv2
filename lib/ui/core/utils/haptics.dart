import 'package:flutter/services.dart';

/// Semantic haptic feedback utility for the 'Serene Editorial' design system.
abstract final class Haptics {
  /// Very light tap for chip toggles, segmented items, or subtle selections.
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Standard light impact for button presses.
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact for successful post generation, copy confirmations, or key checkpoints.
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact for destructive actions (delete, clear) or error states.
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }
}
