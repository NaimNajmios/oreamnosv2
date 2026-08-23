import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Neo-Editorial theme configurations.
/// Mirrors the Android app's three theme modes.
abstract final class AppTheme {
  /// Sharp corners — the defining trait of Neo-Editorial.
  static const ShapeBorder _neoShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  static ThemeData light() {
    return _buildTheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      onPrimary: AppColors.lightOnPrimary,
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onPrimary: AppColors.darkOnPrimary,
    );
  }

  static ThemeData deepBlue() {
    return _buildTheme(
      brightness: Brightness.dark,
      primary: AppColors.deepBluePrimary,
      background: AppColors.deepBlueBackground,
      surface: AppColors.deepBlueSurface,
      onSurface: AppColors.deepBlueOnSurface,
      onPrimary: AppColors.deepBlueOnPrimary,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color onPrimary,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );

    final textTheme = AppTypography.textTheme(onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: _neoShape,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: textTheme.labelLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: surface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: onSurface.withAlpha(153),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: onSurface.withAlpha(31),
        thickness: 1,
      ),
    );
  }
}
