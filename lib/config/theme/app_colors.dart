import 'package:flutter/material.dart';

/// Neo-Editorial color palette for the Oreamnos app.
/// Ported from the Android Socurate app's Color.kt
abstract final class AppColors {
  // === Light Theme ===
  static const Color lightPrimary = Color(0xFFFF4500); // International Orange
  static const Color lightBackground = Color(0xFFFFFFFF); // Neo White
  static const Color lightSurface = Color(0xFFF9F9F9); // Neo Off White
  static const Color lightOnSurface = Color(0xFF000000); // Neo Black
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  // === Dark Theme ===
  static const Color darkPrimary = Color(0xFFFF4500); // International Orange
  static const Color darkBackground = Color(0xFF000000); // Neo Black
  static const Color darkSurface = Color(0xFF121212); // Neo Dark Grey
  static const Color darkOnSurface = Color(0xFFFFFFFF); // Neo White
  static const Color darkOnPrimary = Color(0xFFFFFFFF);

  // === Deep Blue Theme ===
  static const Color deepBluePrimary = Color(0xFF3B82F6); // Electric Blue
  static const Color deepBlueBackground = Color(0xFF0B1120); // Deep Navy
  static const Color deepBlueSurface = Color(0xFF1E293B); // Slate
  static const Color deepBlueOnSurface = Color(0xFFFFFFFF);
  static const Color deepBlueOnPrimary = Color(0xFFFFFFFF);

  // === Shared Accents ===
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}
