import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brutalist typography ramp for the Aperture design system.
/// Uses Space Grotesk for all UI text roles and IBM Plex Mono for numeric & tabular figures.
abstract final class AppTypography {
  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      // Display: Bold (w700), tight tracking
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 57,
        height: 64 / 57,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 45,
        height: 52 / 45,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -1.0,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),

      // Headline: Bold (w700), zero tracking
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),

      // Title: Bold (w700) for all titles
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.1,
      ),

      // Body: Regular (w400)
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),
      bodySmall: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),

      // Label: Bold (w700), stark uppercase style intended
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 1.0,
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 1.0,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 1.0,
      ),
    );
  }

  /// Input text style helper
  static TextStyle input(Color color) {
    return GoogleFonts.spaceGrotesk(
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
