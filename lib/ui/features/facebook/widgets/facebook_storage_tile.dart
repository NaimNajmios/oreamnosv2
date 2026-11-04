import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_storage_service.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/settings_tile.dart';

/// Settings row showing how much space Facebook thumbnails, draft images and
/// stale temp crops use. The dialog exposes a manual sweep.
class FacebookStorageTile extends StatefulWidget {
  const FacebookStorageTile({super.key});

  @override
  State<FacebookStorageTile> createState() => _FacebookStorageTileState();
}

class _FacebookStorageTileState extends State<FacebookStorageTile> {
  FacebookStorageReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final report = await getIt<FacebookStorageService>().report();
      if (mounted) setState(() => _report = report);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return SettingsTile(
      leadingIcon: Icons.storage_rounded,
      title: 'Storage',
      subtitle: report == null
          ? 'Measure thumbnails, drafts and temp photos'
          : '${report.formattedTotal} used · ${report.draftCount} drafts',
      onTap: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => FacebookStorageDialog(report: report),
        );
        if (mounted) _load();
      },
    );
  }
}

class FacebookStorageDialog extends StatefulWidget {
  const FacebookStorageDialog({super.key, this.report});

  final FacebookStorageReport? report;

  static Future<void> show(
    BuildContext context, {
    FacebookStorageReport? report,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => FacebookStorageDialog(report: report),
    );
  }

  @override
  State<FacebookStorageDialog> createState() => _FacebookStorageDialogState();
}

class _FacebookStorageDialogState extends State<FacebookStorageDialog> {
  late FacebookStorageReport? _report = widget.report;
  bool _loading = false;
  bool _sweeping = false;

  Future<void> _sweep() async {
    setState(() => _sweeping = true);
    try {
      final freed = await getIt<FacebookStorageService>().sweep();
      final report = await getIt<FacebookStorageService>().report();
      if (!mounted) return;
      setState(() => _report = report);
      Haptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            freed <= 0
                ? 'Nothing to clean up'
                : 'Cleaned up ${_formatBytes(freed)}',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cleanup failed. Try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sweeping = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final report = await getIt<FacebookStorageService>().report();
      if (mounted) setState(() => _report = report);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _report;
    return AlertDialog(
      title: const Text('Facebook storage'),
      content: SizedBox(
        width: 360,
        child: report == null
            ? const SizedBox(
                height: 96,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _row(theme, 'Post thumbnails', report.formattedHistory),
                  _row(theme, 'Draft images', report.formattedDrafts),
                  _row(theme, 'Temp uploads', report.formattedTemp),
                  const Divider(height: AppSpacing.lg),
                  _row(theme, 'Total', report.formattedTotal, bold: true),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cleanup removes thumbnails for deleted posts, unused '
                      'draft images, and cropped uploads older than 24 hours. '
                      'Published posts and current drafts are never touched.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (_loading || _sweeping) ...[
                    const SizedBox(height: AppSpacing.md),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _sweeping ? null : _refresh,
          child: const Text('Refresh'),
        ),
        TextButton(
          onPressed: _sweeping ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        AppButton(
          label: 'Clean up',
          isLoading: _sweeping,
          height: 40,
          onPressed: _sweeping ? null : _sweep,
        ),
      ],
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
