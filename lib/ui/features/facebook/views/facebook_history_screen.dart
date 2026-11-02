import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

/// Published Posts history (capped at 50). Tap opens the post on Facebook;
/// long-press offers Open / Copy link / Remove.
class FacebookHistoryScreen extends ConsumerWidget {
  const FacebookHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final records = ref.watch(facebookHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Published Posts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: records.isEmpty
          ? EmptyState(
              title: 'Nothing published yet',
              description: 'Publish a generated post or a card and it will show up here.',
              icon: Icons.facebook_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: records.length,
              itemBuilder: (context, index) =>
                  _RecordTile(record: records[index]),
            ),
    );
  }
}

class _RecordTile extends ConsumerWidget {
  const _RecordTile({required this.record});

  final FacebookPostRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _open(context),
      onLongPress: () => _showActions(context, ref),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              record.hasImage ? Icons.image_outlined : Icons.notes_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.formattedTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    if (record.permalink.isEmpty) return;
    try {
      await launchUrl(
        Uri.parse(record.permalink),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    Haptics.lightImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded, size: 20),
              title: const Text('Open post'),
              onTap: () => Navigator.pop(sheetContext, 'open'),
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, size: 20),
              title: const Text('Copy link'),
              onTap: () => Navigator.pop(sheetContext, 'copy'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                'Remove from history',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'open':
        await _open(context);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: record.permalink));
        Haptics.lightImpact();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Post link copied')));
        }
      case 'remove':
        await ref.read(facebookHistoryProvider.notifier).remove(record.id);
    }
  }
}
