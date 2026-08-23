import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../domain/models/custom_pill.dart';
import '../../view_models/settings_view_model.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';

class AddPillDialog extends StatefulWidget {
  final CustomPill? existingPill;

  const AddPillDialog({super.key, this.existingPill});

  static Future<void> show(BuildContext context, {CustomPill? existingPill}) {
    return showDialog(
      context: context,
      builder: (context) => AddPillDialog(existingPill: existingPill),
    );
  }

  @override
  State<AddPillDialog> createState() => _AddPillDialogState();
}

class _AddPillDialogState extends State<AddPillDialog> {
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
        const SnackBar(content: Text('Both fields are required')),
      );
      return;
    }

    final pill = CustomPill(label: label, instruction: instruction);
    final viewModel = context.read<SettingsViewModel>();
    
    if (widget.existingPill != null) {
      // Find index and update
      viewModel.removeCustomPill(widget.existingPill!);
    }
    viewModel.addCustomPill(pill);
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Custom Pill',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            AppInput(
              controller: _labelController,
              hint: 'e.g. Translate',
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _instructionController,
              hint: 'e.g. Translate this to English',
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'SAVE',
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
