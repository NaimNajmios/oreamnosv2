import 'package:flutter/services.dart';

/// Semantic haptic feedback vocabulary from the Sciuro design system.
abstract final class Haptics {
  /// Selection event — subtle tap for chip toggles, segmented pill toggles, and tab switches.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Success event — medium impact when post generation or file export succeeds.
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Warning event — light impact for undo actions, character warnings, or rate limits.
  static Future<void> warning() async {
    await HapticFeedback.lightImpact();
  }

  /// Error event — heavy impact for destructive actions (clearing history) or failed queries.
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  /// Transfer / Match event — light impact for matched intents or copied snippets.
  static Future<void> transferMatch() async {
    await HapticFeedback.lightImpact();
  }

  // === Backward-compatible aliases ===
  static Future<void> selectionClick() => selection();
  static Future<void> lightImpact() => warning();
  static Future<void> mediumImpact() => success();
  static Future<void> heavyImpact() => error();
}
