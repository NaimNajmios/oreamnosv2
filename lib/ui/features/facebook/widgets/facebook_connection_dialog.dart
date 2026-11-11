import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

enum _TokenMode { user, page }

/// Facebook connection dialog. A user token is exchanged for Page tokens via
/// `/me/accounts`; only the derived Page tokens are stored. The page-token
/// path remains for users who already have one.
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
  final _controller = TextEditingController();
  _TokenMode _mode = _TokenMode.user;
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorText;

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
    final token = _controller.text.trim();
    try {
      final notifier = ref.read(facebookViewModelProvider.notifier);
      final error = _mode == _TokenMode.user
          ? await notifier.connectWithUserToken(token)
          : await notifier.connectPageToken(token);
      if (error != null) {
        // Never surface or log the raw token or URL — message only.
        if (mounted) setState(() => _errorText = error);
        return;
      }
      if (mounted) {
        Haptics.mediumImpact();
        final connection = ref.read(facebookViewModelProvider);
        final cleared = await _clearClipboardIfToken(token);
        if (!mounted) return;
        Navigator.of(context).pop();
        final base = connection.hasMultiplePages
            ? 'Connected ${connection.pages.length} Pages · '
                  '${connection.pageName}'
            : 'Connected · ${connection.pageName}';
        final message = cleared ? '$base · Clipboard cleared' : base;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Clears the clipboard only when it still holds the token just submitted,
  /// so unrelated clipboard content is never destroyed.
  Future<bool> _clearClipboardIfToken(String token) async {
    if (token.isEmpty) return false;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final current = data?.text?.trim();
      if (current != token) return false;
      await Clipboard.setData(const ClipboardData(text: ''));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _disconnectActive() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(facebookViewModelProvider.notifier).disconnectActivePage();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect every Page?'),
        content: const Text(
          'This removes all Page tokens, publish history and drafts from '
          'this device. You can reconnect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Pages'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disconnect all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
    final isUser = _mode == _TokenMode.user;

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
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
                      isUser ? 'Connect Pages' : 'Connect a Page',
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
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<_TokenMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _TokenMode.user,
                    label: Text('User token'),
                  ),
                  ButtonSegment(
                    value: _TokenMode.page,
                    label: Text('Page token'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _isLoading
                    ? null
                    : (selection) {
                        setState(() {
                          _mode = selection.first;
                          _controller.clear();
                          _errorText = null;
                          _obscureText = true;
                        });
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                connection.isConnected
                    ? 'Connected · ${connection.pageName}'
                          '${connection.hasMultiplePages ? ' (+${connection.pages.length - 1} more)' : ''}. '
                          'Paste a token to add or refresh Pages.'
                    : isUser
                    ? 'Recommended. Create a user token in Meta Business Suite with '
                          'pages_show_list, pages_read_engagement and '
                          'pages_manage_posts, then paste it here. All your '
                          'Pages are detected and each Page token is stored '
                          'securely on this device. The user token itself is '
                          'discarded immediately and never saved or logged.'
                    : 'Paste a Page access token. It is verified against '
                          'Facebook before saving and stays in secure storage '
                          'on this device — never logged.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _controller,
                label: isUser ? 'User access token' : 'Page access token',
                hint: 'EAA…',
                maxLines: _obscureText ? 1 : 2,
                obscureText: _obscureText,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _testAndSave,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Try again'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.xs,
                children: [
                  if (connection.isConnected)
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : connection.hasMultiplePages
                          ? _disconnectActive
                          : _disconnectAll,
                      child: Text(
                        connection.hasMultiplePages
                            ? 'Disconnect this Page'
                            : 'Disconnect',
                      ),
                    ),
                  if (connection.hasMultiplePages)
                    TextButton(
                      onPressed: _isLoading ? null : _disconnectAll,
                      child: const Text('Disconnect all'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  AppButton(
                    label: isUser ? 'Find Pages' : 'Test & Save',
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
