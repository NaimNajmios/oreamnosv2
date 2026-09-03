import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/custom_pill.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class AddPillDialog extends ConsumerStatefulWidget {
  final CustomPill? existingPill;

  const AddPillDialog({super.key, this.existingPill});

  static Future<void> show(BuildContext context, {CustomPill? existingPill}) {
    return showDialog(
      context: context,
      builder: (context) => AddPillDialog(existingPill: existingPill),
    );
  }

  @override
  ConsumerState<AddPillDialog> createState() => _AddPillDialogState();
}

class _AddPillDialogState extends ConsumerState<AddPillDialog> {
  final _labelController = TextEditingController();
  final _instructionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingPill != null) {
      _labelController.text = widget.existingPill!.label;
      _instructionController.text = widget.existingPill!.instruction;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _save() {
    final label = _labelController.text.trim();
    final instruction = _instructionController.text.trim();

    if (label.isEmpty || instruction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both label and instruction are required'),
        ),
      );
      return;
    }

    final pill = CustomPill(
      id: widget.existingPill?.id,
      label: label,
      instruction: instruction,
    );
    final viewModel = ref.read(settingsViewModelProvider.notifier);

    if (widget.existingPill != null) {
      viewModel.removeCustomPill(widget.existingPill!);
    }
    viewModel.addCustomPill(pill);
    Haptics.mediumImpact();

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingPill != null;

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
                isEditing ? 'Edit Custom Pill' : 'Add Custom Pill',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Define a quick AI refinement prompt for your generated posts.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _labelController,
                label: 'Pill Label',
                hint: 'e.g. Translate to English, Punchy Hook',
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _instructionController,
                label: 'Prompt Instruction',
                hint: 'e.g. Translate this post into standard English while retaining the football hype.',
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
                  AppButton(
                    label: isEditing ? 'Save Changes' : 'Add Pill',
                    height: 44,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
