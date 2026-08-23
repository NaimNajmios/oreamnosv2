import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Strict typography ramp for the 'Serene Editorial' design system.
/// Uses Inter with explicit font sizes, line heights, and weights.
abstract final class AppTypography {
  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      // Display: Reading mode headline
      displayLarge: GoogleFonts.inter(
        fontSize: 30,
        height: 38 / 30,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.4,
      ),
      // Headline: Screen titles
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      // Title: Section headers and card titles
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      // Body: Generated post, reading, lists, metadata
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 26 / 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 22 / 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      // Labels: Buttons, chips, captions
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Input text style helper
  static TextStyle input(Color color) {
    return GoogleFonts.inter(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  /// Monospace text style for code/debug logs
  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
