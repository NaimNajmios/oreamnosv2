import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 'Aperture' ThemeData builder.
abstract final class AppTheme {
  static ThemeData flash({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.light,
      bg: AppColors.flashBg,
      surface: AppColors.flashSurface,
      surfaceMuted: AppColors.flashSurfaceMuted,
      border: AppColors.flashBorder,
      textPrimary: AppColors.flashTextPrimary,
      textSecondary: AppColors.flashTextSecondary,
      textTertiary: AppColors.flashTextTertiary,
      accent: AppColors.flashAccent,
      accentSoft: AppColors.flashAccentSoft,
      dynamicColorScheme: dynamicColorScheme,
      paletteName: 'Flash',
    );
  }

  static ThemeData voidTheme({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.voidBg,
      surface: AppColors.voidSurface,
      surfaceMuted: AppColors.voidSurfaceMuted,
      border: AppColors.voidBorder,
      textPrimary: AppColors.voidTextPrimary,
      textSecondary: AppColors.voidTextSecondary,
      textTertiary: AppColors.voidTextTertiary,
      accent: AppColors.voidAccent,
      accentSoft: AppColors.voidAccentSoft,
      dynamicColorScheme: dynamicColorScheme,
      paletteName: 'Void',
    );
  }

  // === Theme Builder with WCAG Contrast Checking ===
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceMuted,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color accent,
    required Color accentSoft,
    required String paletteName,
    ColorScheme? dynamicColorScheme,
  }) {
    final isDark = brightness == Brightness.dark;

    // Runtime contrast ratio validation (WCAG 3.0:1 floor)
    _validateContrast(textPrimary, bg, minRatio: 3.0, contextName: '$paletteName (text on bg)');
    _validateContrast(textPrimary, surface, minRatio: 3.0, contextName: '$paletteName (text on surface)');

    final onAccentColor = isDark ? Colors.black : Colors.white;

    final colorScheme = dynamicColorScheme != null
        ? dynamicColorScheme.copyWith(
            surface: surface,
            onSurface: textPrimary,
            outline: border,
            outlineVariant: border,
            surfaceContainerHighest: surfaceMuted,
          )
        : ColorScheme(
            brightness: brightness,
            primary: accent,
            onPrimary: onAccentColor,
            primaryContainer: accentSoft,
            onPrimaryContainer: isDark ? Colors.white : Colors.black,
            secondary: accent,
            onSecondary: onAccentColor,
            surface: surface,
            onSurface: textPrimary,
            surfaceContainer: surfaceMuted,
            surfaceContainerHighest: surfaceMuted,
            outline: border,
            outlineVariant: border,
            error: AppColors.error,
            onError: Colors.white,
          );


    final textTheme = AppTypography.textTheme(textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXs, // 0px
          side: BorderSide(color: border, width: 2), // 2px border
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill, // 999px
        ),
        backgroundColor: surfaceMuted,
        selectedColor: accent,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: textPrimary,
        ),
        side: BorderSide(color: border, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccentColor,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 2),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyLarge?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusXs, // 0px
          borderSide: BorderSide(color: border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusXs,
          borderSide: BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusXs,
          borderSide: BorderSide(color: textPrimary, width: 4), // Extremely thick when focused
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusXs,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        elevation: 0,
        indicatorColor: Colors.transparent, // No pill indicator
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return AppTypography.mono(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: textPrimary,
            letterSpacing: 1.0,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: textPrimary,
            size: isSelected ? 28 : 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 2, // 2px dividers
        space: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXs, // 0px
          side: BorderSide(color: border, width: 2),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        elevation: 0,
        modalBarrierColor: isDark 
            ? Colors.black.withValues(alpha: 0.85) 
            : Colors.black.withValues(alpha: 0.85),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 0px
          side: BorderSide(color: Colors.transparent),
        ),
        showDragHandle: true,
        dragHandleColor: border,
        dragHandleSize: const Size(48, 4), // sharper longer handle
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return onAccentColor;
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textPrimary;
          }
          return Colors.transparent;
        }),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),
    );
  }

  // === Relative Luminance and Contrast Calculation ===
  static double _channelLuminance(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _colorLuminance(Color color) {
    final r = _channelLuminance(color.r);
    final g = _channelLuminance(color.g);
    final b = _channelLuminance(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double calculateContrastRatio(Color c1, Color c2) {
    final l1 = _colorLuminance(c1);
    final l2 = _colorLuminance(c2);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static void _validateContrast(
    Color foreground,
    Color background, {
    double minRatio = 3.0,
    required String contextName,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    assert(
      ratio >= minRatio,
      'Contrast violation in $contextName: ratio ${ratio.toStringAsFixed(2)}:1 is below minimum ${minRatio.toStringAsFixed(1)}:1',
    );
  }
}
