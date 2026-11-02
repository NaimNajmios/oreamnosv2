import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

/// Facebook Page connection dialog — mirrors `ApiKeyDialog`:
/// one token field + **Test & Save**. The connection persists only after
/// `GET /me` verification succeeds; the resolved Page name then shows in
/// the settings tile. Disconnect lives here, not in the settings screen.
class FacebookConnectionDialog extends ConsumerStatefulWidget {
  const FacebookConnectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const FacebookConnectionDialog(),
    );
  }

  @override
  ConsumerState<FacebookConnectionDialog> createState() =>
      _FacebookConnectionDialogState();
}

class _FacebookConnectionDialogState
    extends ConsumerState<FacebookConnectionDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadExistingToken();
  }

  Future<void> _loadExistingToken() async {
    final existing = await getIt<PreferencesService>().getFacebookPageToken();
    if (mounted && existing != null && existing.isNotEmpty) {
      setState(() => _controller.text = existing);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final error = await ref
          .read(facebookViewModelProvider.notifier)
          .connect(_controller.text);
      if (error != null) {
        // Never surface or log the raw token or URL — message only.
        if (mounted) setState(() => _errorText = error);
        return;
      }
      if (mounted) {
        Haptics.mediumImpact();
        Navigator.of(context).pop();
        final pageName = ref.read(facebookViewModelProvider).pageName;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Connected · $pageName')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(facebookViewModelProvider.notifier).disconnect();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connection = ref.watch(facebookViewModelProvider);

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
                      Icons.facebook_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Connect Facebook Page',
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
                connection.isConnected
                    ? 'Connected · ${connection.pageName}. Paste a new token to switch Pages.'
                    : 'Create a Page access token in Meta Business Suite, then paste it here. It is verified against Facebook before saving and stays in secure storage on this device — never logged. Posts are only public once the Meta app is in Live mode.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _controller,
                label: 'Page access token',
                hint: 'EAA…',
                maxLines: 2,
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
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (connection.isConnected) ...[
                    TextButton(
                      onPressed: _isLoading ? null : _disconnect,
                      child: const Text('Disconnect'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: 'Test & Save',
                    isLoading: _isLoading,
                    height: 44,
                    onPressed: _isLoading ? null : _testAndSave,
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
