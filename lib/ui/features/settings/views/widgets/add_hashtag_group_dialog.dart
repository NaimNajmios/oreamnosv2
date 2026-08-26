import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/hashtag_group.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class AddHashtagGroupDialog extends ConsumerStatefulWidget {
  const AddHashtagGroupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AddHashtagGroupDialog(),
    );
  }

  @override
  ConsumerState<AddHashtagGroupDialog> createState() =>
      _AddHashtagGroupDialogState();
}

class _AddHashtagGroupDialogState extends ConsumerState<AddHashtagGroupDialog> {
  final _nameController = TextEditingController();
  final _hashtagsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final hashtags = _hashtagsController.text.trim();

    if (name.isEmpty || hashtags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both group name and hashtags are required'),
        ),
      );
      return;
    }

    final group = HashtagGroup(
      id: const Uuid().v4(),
      name: name,
      hashtags: hashtags,
    );
    Haptics.mediumImpact();
    ref.read(settingsViewModelProvider.notifier).addHashtagGroup(group);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Hashtag Group',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Define a named set of hashtags to append to generated posts.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _nameController,
                label: 'Group Name',
                hint: 'e.g. Premier League, Harimau Malaya',
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _hashtagsController,
                label: 'Hashtags',
                hint: '#HarimauMalaya #LigaSuper #FootballMY',
                minLines: 3,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(label: 'Save Group', height: 44, onPressed: _save),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
