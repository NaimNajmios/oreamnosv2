import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class ApiKeyDialog extends StatefulWidget {
  const ApiKeyDialog({super.key, required this.provider});

  final AiProvider provider;

  static Future<void> show(BuildContext context, AiProvider provider) {
    return showDialog(
      context: context,
      builder: (context) => ApiKeyDialog(provider: provider),
    );
  }

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final viewModel = context.read<SettingsViewModel>();
    final existingKey = await viewModel.getApiKeyForProvider(widget.provider);
    if (mounted) {
      if (existingKey != null) {
        _controller.text = existingKey;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<SettingsViewModel>().setApiKey(widget.provider, key);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.provider.displayName} API Key saved')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        'Configure ${widget.provider.displayName}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your API key to enable content generation.'),
          const SizedBox(height: 16),
          SizedBox(
            width: 400,
            child: AppInput(
              controller: _controller,
              label: 'API Key',
              hint: 'sk-...',
              maxLines: 1,
            ),
          ),
        ],
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
          onPressed: _isLoading ? null : _saveKey,
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

