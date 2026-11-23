import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Dialog with a slider for the reading-mode text size (12–24pt).
class ReadingSizeDialog extends ConsumerWidget {
  const ReadingSizeDialog({super.key});

  static const double minSize = 12.0;
  static const double maxSize = 24.0;

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ReadingSizeDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final state = ref.watch(settingsViewModelProvider);
    final size = state.readingTextSize.clamp(minSize, maxSize).toDouble();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reading text size',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose the size of text in reading mode.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Slider(
                min: minSize,
                max: maxSize,
                divisions: 12,
                label: '$size',
                value: size,
                onChanged: (v) => notifier.setReadingTextSize(v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
