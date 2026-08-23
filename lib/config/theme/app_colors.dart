import 'package:flutter/material.dart';

/// Flat Minimalist color palette for the Oreamnos app.
/// Used as fallbacks when dynamic color is not available.
abstract final class AppColors {
  // === Light Theme ===
  static const Color lightPrimary = Color(0xFFFF4500); // International Orange fallback
  static const Color lightBackground = Color(0xFFF9FAFB); // Soft Off-White
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightOnSurface = Color(0xFF0F172A); // Slate 900
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  // === Dark Theme ===
  static const Color darkPrimary = Color(0xFFFF4500); // International Orange fallback
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkOnSurface = Color(0xFFF8FAFC); // Slate 50
  static const Color darkOnPrimary = Color(0xFFFFFFFF);

  // === Deep Blue Theme ===
  static const Color deepBluePrimary = Color(0xFF3B82F6); // Electric Blue fallback
  static const Color deepBlueBackground = Color(0xFF0B1120); // Deep Navy
  static const Color deepBlueSurface = Color(0xFF1E293B); // Slate
  static const Color deepBlueOnSurface = Color(0xFFFFFFFF);
  static const Color deepBlueOnPrimary = Color(0xFFFFFFFF);

  // === Shared Accents ===
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
}
