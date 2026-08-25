import 'package:flutter/material.dart';

/// Semantic token-based color palette for the 'Serene Editorial' design system.
abstract final class AppColors {
  // === Light Theme Tokens ===
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE7E7EA);
  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextTertiary = Color(0xFFA1A1AA);
  static const Color lightAccent = Color(0xFF4F46E5);
  static const Color lightAccentSoft = Color(0xFFEEF2FF);

  // === Dark Theme Tokens ===
  static const Color darkBg = Color(0xFF0B0B0C);
  static const Color darkSurface = Color(0xFF141416);
  static const Color darkSurfaceMuted = Color(0xFF1D1D20);
  static const Color darkBorder = Color(0xFF2A2A2E);
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF52525B);
  static const Color darkAccent = Color(0xFF818CF8);
  static const Color darkAccentSoft = Color(0xFF1E1B4B);

  // === Deep Blue Theme Tokens ===
  static const Color deepBlueBg = Color(0xFF0B1120);
  static const Color deepBlueSurface = Color(0xFF131D31);
  static const Color deepBlueSurfaceMuted = Color(0xFF1B2742);
  static const Color deepBlueBorder = Color(0xFF24355A);
  static const Color deepBlueTextPrimary = Color(0xFFF8FAFC);
  static const Color deepBlueTextSecondary = Color(0xFF94A3B8);
  static const Color deepBlueTextTertiary = Color(0xFF64748B);
  static const Color deepBlueAccent = Color(0xFF3B82F6);
  static const Color deepBlueAccentSoft = Color(0xFF1E293B);

  // === Midnight Noir Theme Tokens (pure monochrome) ===
  static const Color midnightNoirBg = Color(0xFF000000);
  static const Color midnightNoirSurface = Color(0xFF0A0A0A);
  static const Color midnightNoirSurfaceMuted = Color(0xFF1A1A1A);
  static const Color midnightNoirBorder = Color(0xFF2A2A2A);
  static const Color midnightNoirTextPrimary = Color(0xFFF5F5F5);
  static const Color midnightNoirTextSecondary = Color(0xFFA3A3A3);
  static const Color midnightNoirTextTertiary = Color(0xFF525252);
  static const Color midnightNoirAccent = Color(0xFFFFFFFF);
  static const Color midnightNoirAccentSoft = Color(0xFF262626);

  // === Solarized Light Theme Tokens ===
  static const Color solarizedLightBg = Color(0xFFFDF6E3);
  static const Color solarizedLightSurface = Color(0xFFEEE8D5);
  static const Color solarizedLightSurfaceMuted = Color(0xFFE6DDC3);
  static const Color solarizedLightBorder = Color(0xFF93A1A1);
  static const Color solarizedLightTextPrimary = Color(0xFF073642);
  static const Color solarizedLightTextSecondary = Color(0xFF586E75);
  static const Color solarizedLightTextTertiary = Color(0xFF93A1A1);
  static const Color solarizedLightAccent = Color(0xFF268BD2);
  static const Color solarizedLightAccentSoft = Color(0xFFD6EAF8);

  // === Cyberpunk Theme Tokens (neon) ===
  static const Color cyberpunkBg = Color(0xFF0D0221);
  static const Color cyberpunkSurface = Color(0xFF1A0533);
  static const Color cyberpunkSurfaceMuted = Color(0xFF2A0A4A);
  static const Color cyberpunkBorder = Color(0xFF6A0DAD);
  static const Color cyberpunkTextPrimary = Color(0xFFF0F0FF);
  static const Color cyberpunkTextSecondary = Color(0xFF00F0FF);
  static const Color cyberpunkTextTertiary = Color(0xFFB794F6);
  static const Color cyberpunkAccent = Color(0xFFFE00FE);
  static const Color cyberpunkAccentSoft = Color(0xFF4A0A6B);

  // === Matchday Theme Tokens (stadium light) ===
  static const Color matchdayBg = Color(0xFFF0F2F5);
  static const Color matchdaySurface = Color(0xFFFFFFFF);
  static const Color matchdaySurfaceMuted = Color(0xFFF7F8FA);
  static const Color matchdayBorder = Color(0xFFE2E8F0);
  static const Color matchdayTextPrimary = Color(0xFF0F172A);
  static const Color matchdayTextSecondary = Color(0xFF475569);
  static const Color matchdayTextTertiary = Color(0xFF94A3B8);
  static const Color matchdayAccent = Color(0xFFFF4500);
  static const Color matchdayAccentSoft = Color(0xFFFFEDE5);

  // === Forest Theme Tokens (primary — deep emerald) ===
  static const Color forestBg = Color(0xFF0A1A12);
  static const Color forestSurface = Color(0xFF132A1F);
  static const Color forestSurfaceMuted = Color(0xFF1E3A2E);
  static const Color forestBorder = Color(0xFF2D4A3A);
  static const Color forestTextPrimary = Color(0xFFE8F5E9);
  static const Color forestTextSecondary = Color(0xFFA5D6A7);
  static const Color forestTextTertiary = Color(0xFF6B8F71);
  static const Color forestAccent = Color(0xFF4CAF50);
  static const Color forestAccentSoft = Color(0xFF1B5E20);

  // === Forest Alternate Palette (muted sage — use via feature flag) ===
  static const Color forestAltBg = Color(0xFF111A14);
  static const Color forestAltSurface = Color(0xFF1C2B1E);
  static const Color forestAltSurfaceMuted = Color(0xFF2A3D2C);
  static const Color forestAltBorder = Color(0xFF3A4F3E);
  static const Color forestAltTextPrimary = Color(0xFFE8EDE9);
  static const Color forestAltTextSecondary = Color(0xFFB8C5B9);
  static const Color forestAltTextTertiary = Color(0xFF8A9A8B);
  static const Color forestAltAccent = Color(0xFF7FA883);
  static const Color forestAltAccentSoft = Color(0xFF253528);

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

  static const Color deepBluePrimary = deepBlueAccent;
  static const Color deepBlueBackground = deepBlueBg;
  static const Color deepBlueOnSurface = deepBlueTextPrimary;
  static const Color deepBlueOnPrimary = Colors.white;

  static const Color midnightNoirPrimary = midnightNoirAccent;
  static const Color midnightNoirBackground = midnightNoirBg;
  static const Color midnightNoirOnSurface = midnightNoirTextPrimary;
  static const Color midnightNoirOnPrimary = Colors.black;

  static const Color solarizedLightPrimary = solarizedLightAccent;
  static const Color solarizedLightBackground = solarizedLightBg;
  static const Color solarizedLightOnSurface = solarizedLightTextPrimary;

  static const Color cyberpunkPrimary = cyberpunkAccent;
  static const Color cyberpunkBackground = cyberpunkBg;
  static const Color cyberpunkOnSurface = cyberpunkTextPrimary;

  static const Color matchdayPrimary = matchdayAccent;
  static const Color matchdayBackground = matchdayBg;
  static const Color matchdayOnSurface = matchdayTextPrimary;

  static const Color forestPrimary = forestAccent;
  static const Color forestBackground = forestBg;
  static const Color forestOnSurface = forestTextPrimary;
}
