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

  // === Shared Semantic Accents ===
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

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
}
