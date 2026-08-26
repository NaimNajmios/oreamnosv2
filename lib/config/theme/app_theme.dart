import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 'Threads' ThemeData builder.
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
      paletteName: 'Light',
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
      paletteName: 'Dark',
    );
  }

  static ThemeData deepBlue() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: const Color(0xFF0B1120),
      surface: const Color(0xFF1E293B),
      surfaceMuted: const Color(0xFF334155),
      border: const Color(0xFF1E3A8A),
      textPrimary: const Color(0xFFF8FAFC),
      textSecondary: const Color(0xFFCBD5E1),
      textTertiary: const Color(0xFF94A3B8),
      accent: const Color(0xFF3B82F6),
      accentSoft: const Color(0xFF1D4ED8),
      paletteName: 'Deep Blue',
    );
  }

  static ThemeData midnightNoir() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: const Color(0xFF000000),
      surface: const Color(0xFF171717),
      surfaceMuted: const Color(0xFF262626),
      border: const Color(0xFF404040),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFA3A3A3),
      textTertiary: const Color(0xFF737373),
      accent: const Color(0xFFE5E5E5),
      accentSoft: const Color(0xFF525252),
      paletteName: 'Midnight Noir',
    );
  }

  static ThemeData solarizedLight({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.light,
      bg: const Color(0xFFFDF6E3),
      surface: const Color(0xFFEEE8D5),
      surfaceMuted: const Color(0xFFE5DBC1),
      border: const Color(0xFFCCC5B2),
      textPrimary: const Color(0xFF073642),
      textSecondary: const Color(0xFF586E75),
      textTertiary: const Color(0xFF839496),
      accent: const Color(0xFF268BD2),
      accentSoft: const Color(0xFF93A1A1),
      dynamicColorScheme: dynamicColorScheme,
      paletteName: 'Solarized Light',
    );
  }

  static ThemeData cyberpunk() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: const Color(0xFF0D0221),
      surface: const Color(0xFF1D0B3B),
      surfaceMuted: const Color(0xFF2C1654),
      border: const Color(0xFFFF003C),
      textPrimary: const Color(0xFF00FFCC),
      textSecondary: const Color(0xFFFF003C),
      textTertiary: const Color(0xFFFF003C).withValues(alpha: 0.5),
      accent: const Color(0xFFFF003C),
      accentSoft: const Color(0xFF9D002A),
      paletteName: 'Cyberpunk',
    );
  }

  static ThemeData matchday({ColorScheme? dynamicColorScheme}) {
    return _buildTheme(
      brightness: Brightness.light,
      bg: const Color(0xFFFFFFFF),
      surface: const Color(0xFFF3F4F6),
      surfaceMuted: const Color(0xFFE5E7EB),
      border: const Color(0xFFD1D5DB),
      textPrimary: const Color(0xFF111827),
      textSecondary: const Color(0xFF4B5563),
      textTertiary: const Color(0xFF9CA3AF),
      accent: const Color(0xFFDC2626),
      accentSoft: const Color(0xFFFCA5A5),
      dynamicColorScheme: dynamicColorScheme,
      paletteName: 'Matchday',
    );
  }

  static ThemeData forest() {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: const Color(0xFF0F172A),
      surface: const Color(0xFF1E293B),
      surfaceMuted: const Color(0xFF334155),
      border: const Color(0xFF047857),
      textPrimary: const Color(0xFFF8FAFC),
      textSecondary: const Color(0xFF94A3B8),
      textTertiary: const Color(0xFF64748B),
      accent: const Color(0xFF10B981),
      accentSoft: const Color(0xFF065F46),
      paletteName: 'Forest',
    );
  }

  // === Theme Builder ===
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

    final onAccentColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFFFFFFFF);

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
            onPrimaryContainer: isDark ? Colors.white : accent,
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
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1, // Subtle elevation for Threads
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd, // 16dp
          side: BorderSide.none, // No hard borders
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill, // 24dp
        ),
        backgroundColor: surfaceMuted,
        selectedColor: accentSoft,
        labelStyle: textTheme.labelSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide
            .none, // Usually no border on Threads chips, or very subtle
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccentColor,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill, // 24dp
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ), // Sentence case handled in widget
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill, // 24dp
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd, // 12dp input radius
          borderSide: BorderSide.none, // No outline
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        elevation: 0,
        indicatorColor: Colors.transparent, // Threads has no pill indicator
        height: 60, // Threads is fairly compact
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: isSelected
                ? textPrimary
                : textTertiary, // Dark label on active
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? textPrimary
                : textTertiary, // Dark icon on active
            size: 26,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg, // 24dp
          side: BorderSide.none, // Removed border
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 0,
        modalBarrierColor: Colors.black.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: Colors.transparent),
        ),
        showDragHandle: true,
        dragHandleColor: border,
        dragHandleSize: const Size(36, 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white; // Solid white thumb
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent; // Blue track
          }
          return surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
