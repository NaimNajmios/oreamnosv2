import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../../domain/models/hashtag_group.dart';
import '../../view_models/settings_view_model.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';

class AddHashtagGroupDialog extends StatefulWidget {
  const AddHashtagGroupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AddHashtagGroupDialog(),
    );
  }

  @override
  State<AddHashtagGroupDialog> createState() => _AddHashtagGroupDialogState();
}

class _AddHashtagGroupDialogState extends State<AddHashtagGroupDialog> {
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
        const SnackBar(content: Text('Both fields are required')),
      );
      return;
    }

    final group = HashtagGroup(
      id: const Uuid().v4(),
      name: name,
      hashtags: hashtags,
    );
    context.read<SettingsViewModel>().addHashtagGroup(group);
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
              'Add Hashtag Group',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            AppInput(
              controller: _nameController,
              hint: 'Group Name (e.g. Sports)',
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _hashtagsController,
              hint: '#football #sports',
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
