import 'package:flutter/material.dart';

/// Semantic token-based color palette for the 'Aperture' design system.
abstract final class AppColors {
  // === Flash (Light) Theme Tokens ===
  static const Color flashBg = Color(0xFFFFFFFF);
  static const Color flashSurface = Color(0xFFF5F5F5);
  static const Color flashSurfaceMuted = Color(0xFFEBEBEB);
  static const Color flashBorder = Color(0xFF000000); // Brutalist 100% black border
  static const Color flashTextPrimary = Color(0xFF000000);
  static const Color flashTextSecondary = Color(0xFF404040);
  static const Color flashTextTertiary = Color(0xFF737373);
  static const Color flashAccent = Color(0xFF000000);
  static const Color flashAccentSoft = Color(0xFFE0E0E0);

  // === Void (Dark) Theme Tokens ===
  static const Color voidBg = Color(0xFF000000);
  static const Color voidSurface = Color(0xFF0A0A0A);
  static const Color voidSurfaceMuted = Color(0xFF141414);
  static const Color voidBorder = Color(0xFFFFFFFF); // Brutalist 100% white border
  static const Color voidTextPrimary = Color(0xFFFFFFFF);
  static const Color voidTextSecondary = Color(0xFFBFBFBF);
  static const Color voidTextTertiary = Color(0xFF8C8C8C);
  static const Color voidAccent = Color(0xFFFFFFFF);
  static const Color voidAccentSoft = Color(0xFF1F1F1F);

  // === Shared Semantic Accents ===
  // In Aperture, even semantics are highly restricted. We use pure terminal red for error.
  static const Color success = Color(0xFFFFFFFF);
  static const Color successSoft = Color(0xFF1F1F1F);
  static const Color warning = Color(0xFFFFFFFF);
  static const Color warningSoft = Color(0xFF1F1F1F);
  static const Color error = Color(0xFFFF0000); // Pure stark red
  static const Color errorSoft = Color(0xFF330000);

  /// Categorical tint helpers — Aperture design uses monochrome for everything.
  static Color tintForProvider(String providerId, bool isDark) {
    return isDark ? voidTextPrimary : flashTextPrimary;
  }

  static Color softForProvider(String providerId, bool isDark) {
    return isDark ? voidSurfaceMuted : flashSurfaceMuted;
  }

  // Legacy stubs for compatibility
  static const Color darkTeal = Color(0xFFFFFFFF);
  static const Color lightTeal = Color(0xFF000000);
  static const Color darkTealSoft = Color(0xFF1F1F1F);
  static const Color lightTealSoft = Color(0xFFE0E0E0);

  static const Color darkViolet = Color(0xFFFFFFFF);
  static const Color lightViolet = Color(0xFF000000);
  static const Color darkVioletSoft = Color(0xFF1F1F1F);
  static const Color lightVioletSoft = Color(0xFFE0E0E0);

  static const Color darkAmber = Color(0xFFFFFFFF);
  static const Color lightAmber = Color(0xFF000000);
  static const Color darkAmberSoft = Color(0xFF1F1F1F);
  static const Color lightAmberSoft = Color(0xFFE0E0E0);

  static const Color lightAccent = Color(0xFF000000);
  static const Color darkAccent = Color(0xFFFFFFFF);
  static const Color deepBlueAccent = Color(0xFF000000);
  static const Color midnightNoirAccent = Color(0xFFFFFFFF);
  static const Color solarizedLightAccent = Color(0xFF000000);
  static const Color cyberpunkAccent = Color(0xFFFFFFFF);
  static const Color matchdayAccent = Color(0xFF000000);
  static const Color forestAccent = Color(0xFF000000);
}
