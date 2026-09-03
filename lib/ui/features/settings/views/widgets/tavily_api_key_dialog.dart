import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class TavilyApiKeyDialog extends ConsumerStatefulWidget {
  const TavilyApiKeyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const TavilyApiKeyDialog(),
    );
  }

  @override
  ConsumerState<TavilyApiKeyDialog> createState() => _TavilyApiKeyDialogState();
}

class _TavilyApiKeyDialogState extends ConsumerState<TavilyApiKeyDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final viewModel = ref.read(settingsViewModelProvider.notifier);
    final existingKey = await viewModel.getTavilyApiKey();
    if (mounted && existingKey != null) {
      _controller.text = existingKey;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API Key cannot be empty')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(settingsViewModelProvider.notifier).setTavilyApiKey(key);
      if (mounted) {
        Haptics.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tavily API Key saved')));
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

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.travel_explore_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Web search (Tavily)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Let AI look up live news & scores. Keys stay in secure storage on this device and are never logged.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _controller,
                label: 'API Key',
                hint: 'tvly-...',
                maxLines: 1,
                obscureText: _obscureText,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscureText = !_obscureText);
                  },
                ),
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
                    label: 'Save Key',
                    isLoading: _isLoading,
                    height: 44,
                    onPressed: _isLoading ? null : _saveKey,
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
