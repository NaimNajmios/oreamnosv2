import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/ai_provider.dart';
import '../view_models/settings_view_model.dart';

class ProviderSelectionDialog extends StatelessWidget {
  const ProviderSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ProviderSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<SettingsViewModel>();
    final currentProvider = viewModel.selectedProvider;

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'SELECT AI PROVIDER',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: AiProvider.values.map((provider) {
          final isSelected = currentProvider == provider;
          return ListTile(
            title: Text(provider.displayName),
            trailing: isSelected
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () {
              viewModel.setSelectedProvider(provider);
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

