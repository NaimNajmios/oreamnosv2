import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';

/// Inline autosave status for the composer.
///
/// The row is a live region so screen readers announce state changes, and the
/// failure variant offers a retry that saves immediately instead of waiting for
/// the next debounce.
class FacebookDraftSaveStatus extends StatelessWidget {
  const FacebookDraftSaveStatus({
    super.key,
    required this.state,
    required this.savedAt,
    required this.onRetry,
  });

  final FacebookDraftSaveState state;
  final DateTime? savedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state == FacebookDraftSaveState.idle) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final failed = state == FacebookDraftSaveState.failed;
    final color = failed
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    final (icon, label) = switch (state) {
      FacebookDraftSaveState.pending => (
        Icons.cloud_upload_outlined,
        'Unsaved changes',
      ),
      FacebookDraftSaveState.saving => (
        Icons.cloud_sync_outlined,
        'Saving draft…',
      ),
      FacebookDraftSaveState.saved => (
        Icons.cloud_done_outlined,
        savedAt == null ? 'Draft saved' : 'Draft saved · ${_time(savedAt!)}',
      ),
      FacebookDraftSaveState.failed => (
        Icons.cloud_off_outlined,
        "Couldn't save draft",
      ),
      FacebookDraftSaveState.idle => (Icons.cloud_outlined, ''),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ),
            if (failed) ...[
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _time(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
