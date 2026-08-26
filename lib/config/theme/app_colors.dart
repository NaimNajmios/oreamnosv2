import 'package:flutter/material.dart';

/// Semantic token-based color palette for the 'Threads' design system.
abstract final class AppColors {
  // === Light Theme Tokens ===
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightSurfaceMuted = Color(0xFFF0F0F0);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF737373);
  static const Color lightTextTertiary = Color(0xFFA3A3A3);
  static const Color lightAccent = Color(0xFF0095F6);
  static const Color lightAccentSoft = Color(0xFFE0F2FE);

  // === Dark Theme Tokens ===
  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceMuted = Color(0xFF262626);
  static const Color darkBorder = Color(0xFF2E2E2E);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextTertiary = Color(0xFF737373);
  static const Color darkAccent = Color(0xFF0095F6);
  static const Color darkAccentSoft = Color(0xFF0C4A6E);

  // === Colorful Flat Categorical Tokens (light / dark variants) ===
  // Teal — AI / provider
  static const Color lightTeal = Color(0xFF0EA5E9);
  static const Color lightTealSoft = Color(0xFFE0F2FE);
  static const Color darkTeal = Color(0xFF38BDF8);
  static const Color darkTealSoft = Color(0xFF0C4A6E);
  // Amber — Post/tone/warning
  static const Color lightAmber = Color(0xFFF59E0B);
  static const Color lightAmberSoft = Color(0xFFFEF3C7);
  static const Color darkAmber = Color(0xFFFBBF24);
  static const Color darkAmberSoft = Color(0xFF78350F);
  // Emerald — hashtags/success
  static const Color lightEmerald = Color(0xFF10B981);
  static const Color lightEmeraldSoft = Color(0xFFD1FAE5);
  static const Color darkEmerald = Color(0xFF34D399);
  static const Color darkEmeraldSoft = Color(0xFF064E3B);
  // Violet — usage/analytics
  static const Color lightViolet = Color(0xFF8B5CF6);
  static const Color lightVioletSoft = Color(0xFFEDE9FE);
  static const Color darkViolet = Color(0xFFA78BFA);
  static const Color darkVioletSoft = Color(0xFF4C1D95);

  // === Shared Semantic Accents ===
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

  /// Categorical tint helpers — keep flat, solid fills at ~12% soft alpha elsewhere.
  static Color tintForProvider(String providerId, bool isDark) {
    final id = providerId.toLowerCase();
    if (id.contains('gemini')) return isDark ? darkAccent : lightAccent;
    if (id.contains('groq')) return isDark ? darkEmerald : lightEmerald;
    if (id.contains('openrouter')) return isDark ? darkAmber : lightAmber;
    if (id.contains('cerebras')) return isDark ? darkViolet : lightViolet;
    return isDark ? darkTeal : lightTeal;
  }

  static Color softForProvider(String providerId, bool isDark) {
    final id = providerId.toLowerCase();
    if (id.contains('gemini')) return isDark ? darkAccentSoft : lightAccentSoft;
    if (id.contains('groq')) return isDark ? darkEmeraldSoft : lightEmeraldSoft;
    if (id.contains('openrouter')) return isDark ? darkAmberSoft : lightAmberSoft;
    if (id.contains('cerebras')) return isDark ? darkVioletSoft : lightVioletSoft;
    return isDark ? darkTealSoft : lightTealSoft;
  }

  // Legacy compatibility aliases
  static const Color lightPrimary = lightAccent;
  static const Color lightBackground = lightBg;
  static const Color lightOnSurface = lightTextPrimary;
  static const Color lightOnPrimary = Colors.white;

  static const Color darkPrimary = darkAccent;
  static const Color darkBackground = darkBg;
  static const Color darkOnSurface = darkTextPrimary;
  static const Color darkOnPrimary = Colors.white;
}
