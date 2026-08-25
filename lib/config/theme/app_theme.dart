import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 'Aperture' ThemeData builder.
abstract final class AppTheme {
  static ThemeData lightTheme({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.light,
      bg: AppColors.lightBg,
      surface: AppColors.lightSurface,
      surfaceMuted: AppColors.lightSurfaceMuted,
      border: AppColors.lightBorder,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      textTertiary: AppColors.lightTextTertiary,
      accent: AppColors.lightAccent,
      accentSoft: AppColors.lightAccentSoft,
      dynamicColorScheme: dynamicColorScheme,
    );
  }

  static ThemeData darkTheme({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.darkBg,
      surface: AppColors.darkSurface,
      surfaceMuted: AppColors.darkSurfaceMuted,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      textTertiary: AppColors.darkTextTertiary,
      accent: AppColors.darkAccent,
      accentSoft: AppColors.darkAccentSoft,
      dynamicColorScheme: dynamicColorScheme,
    );
  }

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
    ColorScheme? dynamicColorScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final onAccentColor = isDark ? Colors.black : Colors.white;

    final colorScheme = dynamicColorScheme?.copyWith(
          brightness: brightness,
        ) ??
        ColorScheme(
          brightness: brightness,
          primary: accent,
          onPrimary: onAccentColor,
          primaryContainer: accentSoft,
          onPrimaryContainer: textPrimary,
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

    final textTheme = AppTypography.textTheme(colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg, // 16px
          side: BorderSide(color: colorScheme.outline, width: 1), // 1px subtle border
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        side: BorderSide(color: colorScheme.outline, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyLarge?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd, // 12px
          borderSide: BorderSide.none, // Flat style input
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        elevation: 0,
        indicatorColor: colorScheme.secondaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: colorScheme.onSurface,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: colorScheme.onSurface,
            size: isSelected ? 28 : 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        elevation: 0,
        modalBarrierColor: Colors.black.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Soft top radius
          side: BorderSide(color: Colors.transparent),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
        dragHandleSize: const Size(40, 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

}
