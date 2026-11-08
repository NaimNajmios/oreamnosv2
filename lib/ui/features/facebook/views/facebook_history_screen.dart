import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/utils/facebook_external_links.dart';
import 'package:oreamnos/ui/features/facebook/widgets/post_insights_sheet.dart';

/// Publish history (capped at 50) split into Published and Scheduled tabs.
/// Tap opens a live post; long-press offers copy/reuse/remove, plus
/// reschedule/cancel for scheduled posts.
class FacebookHistoryScreen extends ConsumerStatefulWidget {
  const FacebookHistoryScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<FacebookHistoryScreen> createState() =>
      _FacebookHistoryScreenState();
}

class _FacebookHistoryScreenState extends ConsumerState<FacebookHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(facebookDraftProvider.notifier).reconcileScheduled();
    });
  }

  /// Best-effort sequential refresh, capped so a long history never turns
  /// pull-to-refresh into a burst of Graph calls.
  Future<void> _refreshInsights(List<FacebookPostRecord> records) async {
    final notifier = ref.read(facebookHistoryProvider.notifier);
    for (final record in records.take(10)) {
      if (!mounted) return;
      await notifier.refreshEngagement(record.id);
      if (!mounted) return;
      await notifier.refreshInsights(record.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final records = ref.watch(facebookHistoryProvider);
    final published = records.where((r) => !r.isScheduled).toList();
    final scheduled = records.where((r) => r.isScheduled).toList();
    final syncFailed = ref.watch(facebookDraftProvider).scheduledSyncFailed;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Facebook posts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Published (${published.length})'),
              Tab(text: 'Scheduled (${scheduled.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (syncFailed)
              MaterialBanner(
                content: const Text(
                  'Scheduled posts are not synced with Facebook right now.',
                ),
                leading: const Icon(Icons.cloud_off_rounded, size: 20),
                actions: [
                  TextButton(
                    onPressed: () => ref
                        .read(facebookDraftProvider.notifier)
                        .reconcileScheduled(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _RecordList(
                    records: published,
                    emptyTitle: 'Nothing published yet',
                    emptyDescription: 'Publish a generated post or a card and it will show up here.',
                    onRefresh: () => _refreshInsights(published),
                  ),
                  _RecordList(
                    records: scheduled,
                    emptyTitle: 'Nothing scheduled',
                    emptyDescription: 'Choose Schedule in the composer to publish at a later time.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.records,
    required this.emptyTitle,
    required this.emptyDescription,
    this.onRefresh,
  });

  final List<FacebookPostRecord> records;
  final String emptyTitle;
  final String emptyDescription;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: Icons.facebook_rounded,
      );
    }
    final list = ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) => _RecordTile(record: records[index]),
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class _RecordTile extends ConsumerWidget {
  const _RecordTile({required this.record});

  final FacebookPostRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: record.isPublished ? () => _open(context) : null,
      onLongPress: () => _showActions(context, ref),
      child: Row(
        children: [
          _RecordThumbnail(record: record),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (record.isScheduled)
                      _StatusChip(
                        label: 'Scheduled',
                        color: theme.colorScheme.tertiary,
                        icon: Icons.schedule_rounded,
                      ),
                    if (record.isPublished)
                      _StatusChip(
                        label: 'Published',
                        color: theme.colorScheme.primary,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    if (record.isFailed)
                      _StatusChip(
                        label: 'Failed',
                        color: theme.colorScheme.error,
                        icon: Icons.error_outline_rounded,
                      ),
                    if (record.hasStory)
                      _StatusChip(
                        label: record.storyPublished ? 'Story' : 'Story failed',
                        color: record.storyPublished
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                        icon: Icons.auto_stories_rounded,
                        trailingIcon:
                            record.storyPublished && feedPostUri(record) != null
                            ? const Icon(Icons.open_in_new_rounded, size: 10)
                            : null,
                        semanticsLabel: record.storyPublished
                            ? 'Open the Facebook post for this Story'
                            : null,
                        onTap: record.storyPublished
                            ? () => openFacebookPost(
                                context,
                                record,
                                missingMessage:
                                    'This Story has no feed post to open.',
                              )
                            : null,
                      ),
                    if (record.isScheduled) const SizedBox(width: 6),
                    Text(
                      record.isScheduled
                          ? 'Due ${record.formattedScheduledTime}'
                          : record.formattedTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (record.isScheduled) ...[
                      const SizedBox(width: 6),
                      Text(
                        _countdown(record.scheduledAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (record.pageName.isNotEmpty)
                  Text(
                    record.pageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                if (record.hasInsights)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: () => PostInsightsSheet.show(context, record.id),
                      child: Semantics(
                        button: true,
                        label: 'View post insights',
                        child: Text(
                          _statsLine(record),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            record.isScheduled
                ? Icons.more_horiz_rounded
                : Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  static String _countdown(DateTime? at) {
    if (at == null) return '';
    final diff = at.difference(DateTime.now());
    if (diff.isNegative) return 'due now';
    if (diff.inDays > 0) {
      return 'in ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours > 0) {
      return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'in ${diff.inMinutes}m';
  }

  static String _statsLine(FacebookPostRecord record) {
    String compact(int value) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}m';
      }
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}k';
      }
      return '$value';
    }

    return [
      if (record.uniqueViewers != null)
        '👁 ${compact(record.uniqueViewers!)}'
      else if (record.impressions != null)
        '👁 ${compact(record.impressions!)} (cached)',
      if (record.reactions != null) '👍 ${compact(record.reactions!)}',
      if (record.comments != null) '💬 ${compact(record.comments!)}',
      if (record.shares != null) '↗ ${compact(record.shares!)}',
      if (record.clicks != null) '🔗 ${compact(record.clicks!)} (cached)',
    ].join(' · ');
  }

  Future<void> _open(BuildContext context) async {
    // The full row opens the feed post; Story-only records have no permalink
    // and are intentionally a no-op here (the Story chip explains why).
    await openFacebookPost(context, record);
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    Haptics.lightImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.isPublished)
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded, size: 20),
                title: const Text('Open post'),
                onTap: () => Navigator.pop(sheetContext, 'open'),
              ),
            if (record.isPublished)
              ListTile(
                leading: const Icon(Icons.link_rounded, size: 20),
                title: const Text('Copy link'),
                onTap: () => Navigator.pop(sheetContext, 'copy'),
              ),
            if (record.isPublished)
              ListTile(
                leading: const Icon(Icons.edit_outlined, size: 20),
                title: const Text('Edit caption'),
                onTap: () => Navigator.pop(sheetContext, 'edit_caption'),
              ),
            if (record.isPublished)
              ListTile(
                leading: const Icon(Icons.insights_rounded, size: 20),
                title: const Text('View insights'),
                onTap: () => Navigator.pop(sheetContext, 'view_insights'),
              ),
            if (record.isPublished && record.storyFailed)
              ListTile(
                leading: const Icon(Icons.refresh_rounded, size: 20),
                title: const Text('Retry Story'),
                onTap: () => Navigator.pop(sheetContext, 'retry_story'),
              ),
            if (record.isPublished)
              ListTile(
                leading: const Icon(Icons.comment_outlined, size: 20),
                title: const Text('Comments'),
                onTap: () => Navigator.pop(sheetContext, 'comments'),
              ),
            if (record.isPublished)
              ListTile(
                leading: Icon(
                  Icons.delete_forever_rounded,
                  size: 20,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  'Delete post',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, 'delete_post'),
              ),
            if (record.isScheduled)
              ListTile(
                leading: const Icon(Icons.edit_calendar_rounded, size: 20),
                title: const Text('Reschedule'),
                onTap: () => Navigator.pop(sheetContext, 'reschedule'),
              ),
            if (record.isScheduled)
              ListTile(
                leading: Icon(
                  Icons.event_busy_rounded,
                  size: 20,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  'Cancel schedule',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, 'cancel'),
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, size: 20),
              title: const Text('Copy caption'),
              onTap: () => Navigator.pop(sheetContext, 'copy_caption'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded, size: 20),
              title: const Text('Reuse caption'),
              onTap: () => Navigator.pop(sheetContext, 'reuse'),
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
      case 'edit_caption':
        await _editCaption(context, ref);
      case 'delete_post':
        await _deletePost(context, ref);
      case 'view_insights':
        await PostInsightsSheet.show(context, record.id);
      case 'retry_story':
        final error = await ref
            .read(facebookHistoryProvider.notifier)
            .retryStory(record.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error ?? 'Story published')));
        }
      case 'comments':
        if (!context.mounted) return;
        await context.push(
          RoutePaths.facebookComments,
          extra: {'postId': record.postId, 'snippet': record.snippet},
        );
      case 'copy_caption':
        await Clipboard.setData(ClipboardData(text: record.reusableCaption));
        Haptics.lightImpact();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Caption copied')));
        }
      case 'remove':
        await ref.read(facebookHistoryProvider.notifier).remove(record.id);
      case 'reschedule':
        await _reschedule(context, ref);
      case 'cancel':
        await _cancel(context, ref);
      case 'reuse':
        ref
            .read(facebookDraftProvider.notifier)
            .startDraft(record.reusableCaption);
        if (context.mounted) context.push(RoutePaths.facebookCompose);
    }
  }

  Future<void> _editCaption(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: record.reusableCaption);
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit caption'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Write a caption',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty || !context.mounted) return;
    final error = await ref
        .read(facebookHistoryProvider.notifier)
        .editPublishedPost(record.id, message);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Caption updated')));
  }

  Future<void> _deletePost(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this Facebook post?'),
        content: const Text(
          "It will be removed from Facebook and from this device's history. "
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete post'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await ref
        .read(facebookHistoryProvider.notifier)
        .deletePublishedPost(record.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Post deleted')));
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel scheduled post?'),
        content: const Text(
          'Facebook will no longer publish this post. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel post'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await ref
        .read(facebookDraftProvider.notifier)
        .cancelScheduledPost(record.postId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Scheduled post cancelled')),
    );
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initial = record.scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(FacebookDraftNotifier.maxScheduleLead),
      helpText: 'Reschedule post',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;
    final at = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final error = await ref
        .read(facebookDraftProvider.notifier)
        .reschedulePost(record.postId, at);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Post rescheduled')));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
    this.trailingIcon,
    this.onTap,
    this.semanticsLabel,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Widget? trailingIcon;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 2),
            IconTheme.merge(
              data: IconThemeData(color: color),
              child: trailingIcon!,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusPill,
        child: chip,
      ),
    );
  }
}

class _RecordThumbnail extends StatelessWidget {
  const _RecordThumbnail({required this.record});

  final FacebookPostRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = record.localImagePath;
    final hasThumb = path != null && path.isNotEmpty;

    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusSm,
      child: SizedBox(
        width: 44,
        height: 44,
        child: hasThumb
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: 132,
                errorBuilder: (_, _, _) => _placeholder(theme),
              )
            : _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Icon(
        record.hasImage ? Icons.image_outlined : Icons.notes_rounded,
        size: 18,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
