import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../data/models/app_release.dart';
import '../view_models/update_view_model.dart';

/// Shows the update prompt for [release].
///
/// The caller decides *when* to show it (once per session, or from Settings),
/// so this function never inspects the throttle or the skipped tag.
Future<void> showUpdateDialog(
  BuildContext context,
  WidgetRef ref, {
  required AppRelease release,
  String currentVersion = '',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _UpdateDialog(release: release, currentVersion: currentVersion),
  );
}

class _UpdateDialog extends ConsumerWidget {
  const _UpdateDialog({required this.release, required this.currentVersion});

  final AppRelease release;
  final String currentVersion;

  String get _sizeLabel {
    final bytes = release.apkSizeBytes;
    if (bytes == null || bytes <= 0) return '';
    final megabytes = bytes / (1024 * 1024);
    return megabytes >= 1
        ? '${megabytes.toStringAsFixed(1)} MB'
        : '${(bytes / 1024).round()} KB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(updateViewModelProvider);
    final downloading = state.downloadInProgress;
    final notes = release.body.trim();
    final size = _sizeLabel;
    final versionLine = currentVersion.isEmpty
        ? release.version
        : '$currentVersion → ${release.version}';

    return AlertDialog(
      title: const Text('Update available'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                versionLine,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (release.isPrerelease) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pre-release',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (size.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  size,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (state.downloadError != null && !downloading)
                Text(
                  state.downloadError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                )
              else if (notes.isEmpty)
                Text(
                  'No release notes were published for this version.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                MarkdownBody(
                  data: notes,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    listBullet: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (downloading) ...[
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: state.downloadProgress.clamp(0.0, 1.0),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Downloading update… ${(state.downloadProgress * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: downloading ? null : () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: downloading
              ? null
              : () async {
                  await ref
                      .read(updateViewModelProvider.notifier)
                      .skipThisVersion();
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: const Text('Skip this version'),
        ),
        FilledButton(
          onPressed: downloading || state.installInProgress
              ? null
              : () async {
                  final notifier = ref.read(updateViewModelProvider.notifier);
                  if (state.downloadedApkPath != null) {
                    final installed = await notifier.installUpdate();
                    if (context.mounted) {
                      if (installed) {
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Couldn't install the update."),
                          ),
                        );
                      }
                    }
                  } else {
                    await notifier.startDownload(release: release);
                  }
                },
          child: Text(
            state.installInProgress
                ? 'Installing…'
                : state.downloadedApkPath != null
                ? 'Install'
                : 'Update',
          ),
        ),
      ],
    );
  }
}
