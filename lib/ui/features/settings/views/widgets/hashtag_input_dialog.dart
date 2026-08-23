import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/neo_input.dart';
import '../view_models/settings_view_model.dart';

class HashtagInputDialog extends StatefulWidget {
  const HashtagInputDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const HashtagInputDialog(),
    );
  }

  @override
  State<HashtagInputDialog> createState() => _HashtagInputDialogState();
}

class _HashtagInputDialogState extends State<HashtagInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<SettingsViewModel>();
    _controller = TextEditingController(text: viewModel.defaultHashtags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final viewModel = context.read<SettingsViewModel>();
    await viewModel.setDefaultHashtags(_controller.text.trim());
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'DEFAULT HASHTAGS',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: NeoInput(
          controller: _controller,
          hint: 'e.g. #LFC #YNWA',
          maxLines: 2,
        ),
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
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}

