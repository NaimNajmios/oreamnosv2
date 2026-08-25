import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 'Serene Editorial' ThemeData builder.
abstract final class AppTheme {
  static ThemeData light({ColorScheme? dynamicColorScheme}) {
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

  static ThemeData dark({ColorScheme? dynamicColorScheme}) {
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

  static ThemeData deepBlue() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.deepBlueBg,
      surface: AppColors.deepBlueSurface,
      surfaceMuted: AppColors.deepBlueSurfaceMuted,
      border: AppColors.deepBlueBorder,
      textPrimary: AppColors.deepBlueTextPrimary,
      textSecondary: AppColors.deepBlueTextSecondary,
      textTertiary: AppColors.deepBlueTextTertiary,
      accent: AppColors.deepBlueAccent,
      accentSoft: AppColors.deepBlueAccentSoft,
      dynamicColorScheme: null,
    );
  }

  static ThemeData midnightNoir() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.midnightNoirBg,
      surface: AppColors.midnightNoirSurface,
      surfaceMuted: AppColors.midnightNoirSurfaceMuted,
      border: AppColors.midnightNoirBorder,
      textPrimary: AppColors.midnightNoirTextPrimary,
      textSecondary: AppColors.midnightNoirTextSecondary,
      textTertiary: AppColors.midnightNoirTextTertiary,
      accent: AppColors.midnightNoirAccent,
      accentSoft: AppColors.midnightNoirAccentSoft,
      dynamicColorScheme: null,
    );
  }

  static ThemeData solarizedLight({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.light,
      bg: AppColors.solarizedLightBg,
      surface: AppColors.solarizedLightSurface,
      surfaceMuted: AppColors.solarizedLightSurfaceMuted,
      border: AppColors.solarizedLightBorder,
      textPrimary: AppColors.solarizedLightTextPrimary,
      textSecondary: AppColors.solarizedLightTextSecondary,
      textTertiary: AppColors.solarizedLightTextTertiary,
      accent: AppColors.solarizedLightAccent,
      accentSoft: AppColors.solarizedLightAccentSoft,
      dynamicColorScheme: dynamicColorScheme,
    );
  }

  static ThemeData cyberpunk() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.cyberpunkBg,
      surface: AppColors.cyberpunkSurface,
      surfaceMuted: AppColors.cyberpunkSurfaceMuted,
      border: AppColors.cyberpunkBorder,
      textPrimary: AppColors.cyberpunkTextPrimary,
      textSecondary: AppColors.cyberpunkTextSecondary,
      textTertiary: AppColors.cyberpunkTextTertiary,
      accent: AppColors.cyberpunkAccent,
      accentSoft: AppColors.cyberpunkAccentSoft,
      dynamicColorScheme: null,
    );
  }

  static ThemeData matchday({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.light,
      bg: AppColors.matchdayBg,
      surface: AppColors.matchdaySurface,
      surfaceMuted: AppColors.matchdaySurfaceMuted,
      border: AppColors.matchdayBorder,
      textPrimary: AppColors.matchdayTextPrimary,
      textSecondary: AppColors.matchdayTextSecondary,
      textTertiary: AppColors.matchdayTextTertiary,
      accent: AppColors.matchdayAccent,
      accentSoft: AppColors.matchdayAccentSoft,
      dynamicColorScheme: dynamicColorScheme,
    );
  }

  static ThemeData forest() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.forestBg,
      surface: AppColors.forestSurface,
      surfaceMuted: AppColors.forestSurfaceMuted,
      border: AppColors.forestBorder,
      textPrimary: AppColors.forestTextPrimary,
      textSecondary: AppColors.forestTextSecondary,
      textTertiary: AppColors.forestTextTertiary,
      accent: AppColors.forestAccent,
      accentSoft: AppColors.forestAccentSoft,
      dynamicColorScheme: null,
    );
  }

  static ThemeData forestAlt() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.forestAltBg,
      surface: AppColors.forestAltSurface,
      surfaceMuted: AppColors.forestAltSurfaceMuted,
      border: AppColors.forestAltBorder,
      textPrimary: AppColors.forestAltTextPrimary,
      textSecondary: AppColors.forestAltTextSecondary,
      textTertiary: AppColors.forestAltTextTertiary,
      accent: AppColors.forestAltAccent,
      accentSoft: AppColors.forestAltAccentSoft,
      dynamicColorScheme: null,
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
            onPrimary: isDark ? const Color(0xFF0F172A) : Colors.white,
            primaryContainer: accentSoft,
            onPrimaryContainer: accent,
            secondary: accent,
            onSecondary: isDark ? const Color(0xFF0F172A) : Colors.white,
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
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
        ),
        backgroundColor: surfaceMuted,
        selectedColor: accentSoft,
        labelStyle: textTheme.labelSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: border, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: accentSoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: isSelected ? accent : textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? accent : textSecondary,
            size: 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(color: border, width: 1),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
          side: BorderSide(color: Colors.transparent),
        ),
        showDragHandle: true,
        dragHandleColor: border,
        dragHandleSize: const Size(36, 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentSoft;
          }
          return surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),
    );
  }
}
