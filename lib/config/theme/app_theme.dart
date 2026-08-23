import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Flat Minimalist theme configurations.
abstract final class AppTheme {
  /// Soft rounded corners for minimalist look.
  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius _inputBorderRadius = BorderRadius.all(Radius.circular(12));

  static ThemeData light({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      onPrimary: AppColors.lightOnPrimary,
      dynamicColorScheme: dynamicColorScheme,
    );
  }

  static ThemeData dark({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onPrimary: AppColors.darkOnPrimary,
      dynamicColorScheme: dynamicColorScheme,
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
      dynamicColorScheme: null, // Deep blue overrides dynamic colors
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color onPrimary,
    ColorScheme? dynamicColorScheme,
  }) {
    final colorScheme = dynamicColorScheme?.copyWith(
      surface: background,
    ) ?? ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: background,
      onSurface: onSurface,
    );

    final textTheme = AppTypography.textTheme(colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, // Flat look
        shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: _inputBorderRadius,
          borderSide: BorderSide.none, // No border for minimalist look
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _inputBorderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: surface, // Use surface color for fields
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withAlpha(153),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withAlpha(20),
        thickness: 1,
      ),
    );
  }
}
