import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ThemeSelectionDialog(),
    );
  }

  Color _getThemeSwatch(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return AppColors.lightAccent;
      case AppThemeMode.dark:
        return AppColors.darkAccent;
      case AppThemeMode.deepBlue:
        return AppColors.deepBlueAccent;
      case AppThemeMode.midnightNoir:
        return AppColors.midnightNoirAccent;
      case AppThemeMode.solarizedLight:
        return AppColors.solarizedLightAccent;
      case AppThemeMode.cyberpunk:
        return AppColors.cyberpunkAccent;
      case AppThemeMode.matchday:
        return AppColors.matchdayAccent;
      case AppThemeMode.forest:
        return AppColors.forestAccent;
      case AppThemeMode.system:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<SettingsViewModel>();
    final currentTheme = viewModel.themeMode;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Theme & Appearance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select your preferred color theme.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...AppThemeMode.values.map((mode) {
                final isSelected = currentTheme == mode;
                final swatchColor = _getThemeSwatch(mode);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Haptics.selectionClick();
                      viewModel.setThemeMode(mode);
                      Navigator.of(context).pop();
                    },
                    borderRadius: AppSpacing.borderRadiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: swatchColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              mode.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
