import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';
import 'package:oreamnos/ui/features/facebook/widgets/image_attachment_tile.dart';

/// Compose + publish screen. Seeded via `FacebookDraftNotifier.startDraft`
/// before navigation, so the router needs no `extra`.
class FacebookComposeScreen extends ConsumerStatefulWidget {
  const FacebookComposeScreen({super.key});

  @override
  ConsumerState<FacebookComposeScreen> createState() =>
      _FacebookComposeScreenState();
}

class _FacebookComposeScreenState extends ConsumerState<FacebookComposeScreen> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(facebookDraftProvider).text,
    );
    _textController.addListener(_syncText);
  }

  void _syncText() {
    ref.read(facebookDraftProvider.notifier).setDraftText(_textController.text);
  }

  @override
  void dispose() {
    _textController.removeListener(_syncText);
    _textController.dispose();
    super.dispose();
  }

  void _openConnectionDialog() {
    FacebookConnectionDialog.show(context);
  }

  Future<void> _openPermalink(String permalink) async {
    final uri = Uri.parse(permalink);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        Haptics.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(facebookDraftProvider);
    final connection = ref.watch(facebookViewModelProvider);
    ref.listen<FacebookComposePhase>(
      facebookDraftProvider.select((s) => s.phase),
      (prev, next) {
        if (next == FacebookComposePhase.published &&
            prev != FacebookComposePhase.published) {
          Haptics.mediumImpact();
        }
      },
    );

    final needsConnection = connection.isNotConnected || connection.isExpired;
    final canPublish =
        draft.hasText && !draft.isPublishing && connection.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Publish to Facebook',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.base),
        child: AppButton(
          label: draft.isPublished
              ? 'Published ✓'
              : 'Publish to ${connection.pageName.isEmpty ? 'Facebook' : connection.pageName}',
          isLoading: draft.isPublishing,
          onPressed: canPublish
              ? () => ref.read(facebookDraftProvider.notifier).publish()
              : null,
          icon: draft.isPublished ? Icons.check_rounded : Icons.public_rounded,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.base,
          children: [
            _PageChip(
              pageName: connection.pageName,
              needsConnection: needsConnection,
              onOpenConnection: _openConnectionDialog,
            ),
            AppCardLike(
              child: AppInput(
                controller: _textController,
                label: 'Post text',
                hint: 'Plain text only — markdown is stripped automatically',
                minLines: 5,
                maxLines: 10,
                textInputAction: TextInputAction.newline,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_textController.text.length} chars',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            ImageAttachmentTile(
              imagePath: draft.imagePath,
              onAttachGallery: () => ref
                  .read(facebookDraftProvider.notifier)
                  .attachImage(ImageSource.gallery),
              onAttachCamera: () => ref
                  .read(facebookDraftProvider.notifier)
                  .attachImage(ImageSource.camera),
              onRemove: () =>
                  ref.read(facebookDraftProvider.notifier).removeImage(),
              onReplace: () => ref
                  .read(facebookDraftProvider.notifier)
                  .attachImage(ImageSource.gallery),
            ),
            if (draft.isPublished && draft.result != null)
              _PublishedPanel(
                permalink: draft.result!.permalink,
                onView: () => _openPermalink(draft.result!.permalink),
                onDone: () => context.pop(),
              ),
            if (draft.phase == FacebookComposePhase.publishError &&
                draft.error != null)
              _ErrorPanel(
                message: draft.error!.message,
                needsReconnect: draft.error!.needsReconnect,
                onRetry: () =>
                    ref.read(facebookDraftProvider.notifier).publish(),
                onReconnect: _openConnectionDialog,
              ),
          ],
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.pageName,
    required this.needsConnection,
    required this.onOpenConnection,
  });

  final String pageName;
  final bool needsConnection;
  final VoidCallback onOpenConnection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = pageName.isNotEmpty;
    return InkWell(
      onTap: onOpenConnection,
      borderRadius: AppSpacing.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: needsConnection
                ? theme.colorScheme.error.withValues(alpha: 0.5)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.facebook_rounded,
              size: 20,
              color: connected && !needsConnection
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                connected && !needsConnection ? pageName : connectionLabel(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              needsConnection
                  ? Icons.warning_amber_rounded
                  : Icons.edit_outlined,
              size: 18,
              color: needsConnection
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String connectionLabel() =>
      pageName.isEmpty ? 'Not connected — tap to connect' : 'Reconnect Page';
}

class AppCardLike extends StatelessWidget {
  const AppCardLike({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

class _PublishedPanel extends StatelessWidget {
  const _PublishedPanel({
    required this.permalink,
    required this.onView,
    required this.onDone,
  });

  final String permalink;
  final VoidCallback onView;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCardLike(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Published! Live on your Page.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('View on Facebook'),
          ),
          TextButton.icon(
            onPressed: () async {
              // Never copy through a log path — plain clipboard only.
              await Clipboard.setData(ClipboardData(text: permalink));
              if (context.mounted) {
                Haptics.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post link copied')),
                );
              }
            },
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Copy link'),
          ),
          TextButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.needsReconnect,
    required this.onRetry,
    required this.onReconnect,
  });

  final String message;
  final bool needsReconnect;
  final VoidCallback onRetry;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCardLike(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          needsReconnect
              ? TextButton.icon(
                  onPressed: onReconnect,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reconnect Page'),
                )
              : TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
        ],
      ),
    );
  }
}
