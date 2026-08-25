import 'package:flutter/material.dart';

/// Semantic token-based color palette for the Minimalist flat design system.
abstract final class AppColors {
  // === Light Theme Tokens ===
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF9F9F9);
  static const Color lightSurfaceMuted = Color(0xFFF2F2F2);
  static const Color lightBorder = Color(0xFFE5E5E5); // Subtle grey border
  static const Color lightTextPrimary = Color(0xFF171717);
  static const Color lightTextSecondary = Color(0xFF737373);
  static const Color lightTextTertiary = Color(0xFFA3A3A3);
  static const Color lightAccent = Color(0xFF000000);
  static const Color lightAccentSoft = Color(0xFFE5E5E5);

  // === Dark Theme Tokens ===
  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF0F0F0F);
  static const Color darkSurfaceMuted = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF262626); // Subtle dark grey border
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextTertiary = Color(0xFF737373);
  static const Color darkAccent = Color(0xFFFFFFFF);
  static const Color darkAccentSoft = Color(0xFF262626);

  // === Shared Semantic Accents ===
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);

  /// Categorical tint helpers
  static Color tintForProvider(String providerId, bool isDark) {
    return isDark ? darkTextPrimary : lightTextPrimary;
  }

  static Color softForProvider(String providerId, bool isDark) {
    return isDark ? darkSurfaceMuted : lightSurfaceMuted;
  }

  // Legacy stubs for compatibility
  static const Color darkTeal = Color(0xFF14B8A6);
  static const Color lightTeal = Color(0xFF0D9488);
  static const Color darkTealSoft = Color(0xFF042F2E);
  static const Color lightTealSoft = Color(0xFFCCFBF1);

  static const Color darkViolet = Color(0xFF8B5CF6);
  static const Color lightViolet = Color(0xFF7C3AED);
  static const Color darkVioletSoft = Color(0xFF2E1065);
  static const Color lightVioletSoft = Color(0xFFEDE9FE);

  static const Color darkAmber = Color(0xFFF59E0B);
  static const Color lightAmber = Color(0xFFD97706);
  static const Color darkAmberSoft = Color(0xFF451A03);
  static const Color lightAmberSoft = Color(0xFFFEF3C7);

  static const Color lightAccentFallbacks = Color(0xFF000000);
  static const Color darkAccentFallbacks = Color(0xFFFFFFFF);
  static const Color deepBlueAccent = Color(0xFF3B82F6);
  static const Color midnightNoirAccent = Color(0xFFFFFFFF);
  static const Color solarizedLightAccent = Color(0xFF000000);
  static const Color cyberpunkAccent = Color(0xFFEC4899);
  static const Color matchdayAccent = Color(0xFF10B981);
  static const Color forestAccent = Color(0xFF059669);
}
