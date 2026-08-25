import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Strict typography ramp for the Sciuro-inspired design system.
/// Uses Inter for all UI text roles and IBM Plex Mono for numeric & tabular figures.
abstract final class AppTypography {
  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      // Display: ExtraBold (w800), zero tracking
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        height: 64 / 57,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: 0,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        height: 52 / 45,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: 0,
      ),

      // Headline: Bold (w700), zero tracking
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),

      // Title: Bold (w700) for Large, Medium (w500) for Medium/Small
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),

      // Body: Regular (w400), positive tracking increasing as size decreases
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.4,
      ),

      // Label: Medium (w500), positive tracking
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w500,
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

  /// Numeric / Monospace text style for figures, tokens, latencies, counters, debug logs
  /// Uses IBM Plex Mono for clean tabular alignment.
  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Specialized numeric figure style for high-prominence metrics
  static TextStyle figure({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.5,
    );
  }
}
