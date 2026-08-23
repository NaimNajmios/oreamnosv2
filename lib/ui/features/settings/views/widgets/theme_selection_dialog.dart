import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ThemeSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<SettingsViewModel>();
    final currentTheme = viewModel.themeMode;

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'APPEARANCE',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: AppThemeMode.values.map((mode) {
          final isSelected = currentTheme == mode;
          return ListTile(
            title: Text(mode.label),
            trailing: isSelected
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () {
              viewModel.setThemeMode(mode);
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            foregroundColor: theme.colorScheme.onSurface,
          ),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}

