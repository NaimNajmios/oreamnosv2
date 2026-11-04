import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_draft_store.dart';
import 'package:oreamnos/data/services/facebook_workflow_store.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_storage_tile.dart';
import 'package:oreamnos/ui/features/facebook/widgets/page_switcher_sheet.dart';
import 'package:oreamnos/ui/features/publish/view_models/facebook_drafts_view_model.dart';

/// Tab-level home for publishing: Page, new post, drafts, schedule and
/// recent posts. Detail screens stay full-screen pushes.
class PublishHubScreen extends ConsumerStatefulWidget {
  const PublishHubScreen({super.key});

  @override
  ConsumerState<PublishHubScreen> createState() => _PublishHubScreenState();
}

class _PublishHubScreenState extends ConsumerState<PublishHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    ref.read(facebookDraftsProvider.notifier).refresh();
    if (ref.read(facebookViewModelProvider).isConnected) {
      await ref.read(facebookDraftProvider.notifier).reconcileScheduled();
    }
  }

  Future<void> _newPost() async {
    ref.read(facebookDraftProvider.notifier).startEmptyDraft();
    await context.push(RoutePaths.facebookCompose);
    if (mounted) _refresh();
  }

  Future<void> _continueDraft(FacebookDraftRecord? saved) async {
    final active = ref.read(facebookDraftProvider);
    if (active.isEmpty && saved != null) {
      final opened = await ref
          .read(facebookDraftProvider.notifier)
          .openDraft(saved.id);
      if (!opened) return;
    }
    if (!mounted) return;
    await context.push(RoutePaths.facebookCompose);
    if (mounted) _refresh();
  }

  Future<void> _openHistory({required String tab}) async {
    await context.push('${RoutePaths.facebookHistory}?tab=$tab');
    if (mounted) _refresh();
  }

  Future<void> _openDrafts() async {
    await context.push(RoutePaths.facebookDrafts);
    if (mounted) _refresh();
  }

  Future<void> _openWorkflows() async {
    await context.push(RoutePaths.facebookWorkflows);
    if (mounted) _refresh();
  }

  void _openPage() {
    final connection = ref.read(facebookViewModelProvider);
    if (connection.pages.isEmpty || !connection.isConnected) {
      FacebookConnectionDialog.show(context);
    } else {
      PageSwitcherSheet.show(context);
    }
  }

  Future<void> _retryStory(FacebookPostRecord record) async {
    final error = await ref
        .read(facebookHistoryProvider.notifier)
        .retryStory(record.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Story published')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connection = ref.watch(facebookViewModelProvider);
    final history = ref.watch(facebookHistoryProvider);
    final drafts = ref.watch(facebookDraftsProvider);
    final activeDraft = ref.watch(facebookDraftProvider);
    final store = getIt<FacebookWorkflowStore>();
    final workflow = store.defaultForPage(connection.activePageId);

    final scheduled = history.where((r) => r.isScheduled).toList()
      ..sort(
        (a, b) => (a.scheduledAt ?? DateTime.now()).compareTo(
          b.scheduledAt ?? DateTime.now(),
        ),
      );
    final published = history.where((r) => !r.isScheduled).toList();
    final nextScheduled = scheduled.isEmpty ? null : scheduled.first;
    final recent = published.take(3).toList();
    final continueDraft = activeDraft.isEmpty
        ? (drafts.isEmpty ? null : drafts.first)
        : null;
    final hasActiveDraft = !activeDraft.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Publish',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: connection.isConnected ? 'Switch Page' : 'Connect Page',
            onPressed: _openPage,
            icon: const Icon(Icons.switch_account_rounded, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.xxl,
          ),
          children: [
            _PageHero(
              pageName: connection.pageName,
              pagePictureUrl: connection.pagePictureUrl,
              subtitle: connection.subtitle,
              connected: connection.isConnected,
              expired: connection.isExpired,
              workflowLabel: workflow.destinationLabel,
              onTap: _openPage,
              onConnect: () => FacebookConnectionDialog.show(context),
            ),
            const SizedBox(height: AppSpacing.base),
            _CreateCard(
              enabled: connection.isConnected,
              workflowLabel: workflow.destinationLabel,
              onCreate: _newPost,
              onConnect: () => FacebookConnectionDialog.show(context),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Drafts',
                    value: '${drafts.length}',
                    icon: Icons.drafts_outlined,
                    onTap: _openDrafts,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    label: 'Scheduled',
                    value: '${scheduled.length}',
                    icon: Icons.schedule_rounded,
                    onTap: () => _openHistory(tab: 'scheduled'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    label: 'Published',
                    value: '${published.length}',
                    icon: Icons.public_rounded,
                    onTap: () => _openHistory(tab: 'published'),
                  ),
                ),
              ],
            ),
            if (nextScheduled != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Up next',
                action: 'Scheduled',
                onAction: () => _openHistory(tab: 'scheduled'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ScheduledCard(
                record: nextScheduled,
                onTap: () => _openHistory(tab: 'scheduled'),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(
              title: 'Continue writing',
              action: (hasActiveDraft || continueDraft != null)
                  ? 'Drafts'
                  : null,
              onAction: _openDrafts,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (hasActiveDraft || continueDraft != null)
              _DraftCard(
                text: hasActiveDraft ? activeDraft.text : continueDraft!.text,
                pageName: hasActiveDraft
                    ? connection.pageName
                    : continueDraft!.pageName,
                mediaCount: hasActiveDraft
                    ? activeDraft.media.length
                    : continueDraft!.media.length,
                updatedAt: hasActiveDraft
                    ? DateTime.now()
                    : continueDraft!.updatedAt,
                storyEnabled: hasActiveDraft
                    ? activeDraft.storyEnabled
                    : continueDraft!.storyEnabled,
                onTap: () => _continueDraft(continueDraft),
              )
            else
              _EmptyCard(
                icon: Icons.edit_note_rounded,
                title: 'No drafts yet',
                description: 'Start a post and save it to finish later.',
                actionLabel: connection.isConnected ? 'New post' : null,
                onAction: connection.isConnected ? _newPost : null,
              ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(
              title: 'Recent posts',
              action: published.isEmpty ? null : 'View all',
              onAction: () => _openHistory(tab: 'published'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (recent.isEmpty)
              _EmptyCard(
                icon: Icons.public_rounded,
                title: 'Nothing published yet',
                description: 'Published and scheduled posts will show up here.',
                actionLabel: connection.isConnected ? 'Create a post' : null,
                onAction: connection.isConnected ? _newPost : null,
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (final record in recent)
                      _RecentPostRow(
                        record: record,
                        onTap: () => _openHistory(tab: 'published'),
                        onRetryStory: () => _retryStory(record),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionTitle(title: 'Manage'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  _ManageRow(
                    icon: Icons.drafts_outlined,
                    label: 'Drafts',
                    detail: '${drafts.length} saved',
                    onTap: _openDrafts,
                  ),
                  _ManageRow(
                    icon: Icons.history_rounded,
                    label: 'Published posts',
                    detail: '${published.length} posts',
                    onTap: () => _openHistory(tab: 'published'),
                  ),
                  _ManageRow(
                    icon: Icons.account_tree_outlined,
                    label: 'Publishing workflows',
                    detail: workflow.name,
                    onTap: _openWorkflows,
                  ),
                  _ManageRow(
                    icon: Icons.storage_rounded,
                    label: 'Storage',
                    detail: 'Thumbnails, drafts and temp photos',
                    onTap: () => FacebookStorageDialog.show(context),
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

class _PageHero extends StatelessWidget {
  const _PageHero({
    required this.pageName,
    required this.pagePictureUrl,
    required this.subtitle,
    required this.connected,
    required this.expired,
    required this.workflowLabel,
    required this.onTap,
    required this.onConnect,
  });

  final String pageName;
  final String pagePictureUrl;
  final String subtitle;
  final bool connected;
  final bool expired;
  final String workflowLabel;
  final VoidCallback onTap;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: connected ? onTap : null,
      child: Row(
        children: [
          FacebookPageAvatar(
            pageName: pageName,
            pictureUrl: pagePictureUrl,
            size: 48,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pageName.trim().isEmpty ? 'No Page connected' : pageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: expired
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.account_tree_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      workflowLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!connected)
            TextButton(onPressed: onConnect, child: const Text('Connect'))
          else
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({
    required this.enabled,
    required this.workflowLabel,
    required this.onCreate,
    required this.onConnect,
  });

  final bool enabled;
  final String workflowLabel;
  final VoidCallback onCreate;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.send_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  enabled ? 'Create a post' : 'Connect a Page to start',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            enabled
                ? '$workflowLabel · default workflow for this Page'
                : 'Paste a user or Page token once, then publish here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: enabled ? 'New post' : 'Connect Page',
            onPressed: enabled ? onCreate : onConnect,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _ScheduledCard extends StatelessWidget {
  const _ScheduledCard({required this.record, required this.onTap});

  final FacebookPostRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: theme.colorScheme.tertiary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${record.formattedScheduledTime} · '
                  '${_countdown(record.scheduledAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.text,
    required this.pageName,
    required this.mediaCount,
    required this.updatedAt,
    required this.storyEnabled,
    required this.onTap,
  });

  final String text;
  final String pageName;
  final int mediaCount;
  final DateTime updatedAt;
  final bool storyEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = text.trim().isEmpty
        ? (mediaCount > 0 ? 'Photo post' : 'Empty draft')
        : text.trim().split('\n').first;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    if (pageName.isNotEmpty) pageName,
                    if (mediaCount > 0) '$mediaCount photos',
                    if (storyEnabled) 'Story',
                    _relativeTime(updatedAt),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _RecentPostRow extends StatelessWidget {
  const _RecentPostRow({
    required this.record,
    required this.onTap,
    required this.onRetryStory,
  });

  final FacebookPostRecord record;
  final VoidCallback onTap;
  final VoidCallback onRetryStory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _statsLine(record);
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.public_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [
                      record.pageName,
                      record.formattedTime,
                      if (stats.isNotEmpty) stats,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (record.storyFailed)
              TextButton(
                onPressed: onRetryStory,
                child: const Text('Retry Story'),
              )
            else if (record.storyPublished)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 20),
        title: Text(label),
        subtitle: Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          Haptics.lightImpact();
          onTap();
        },
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          Icon(icon, size: 26, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

String _countdown(DateTime? at) {
  if (at == null) return '';
  final diff = at.difference(DateTime.now());
  if (diff.isNegative) return 'due now';
  if (diff.inDays > 0) return 'in ${diff.inDays}d ${diff.inHours % 24}h';
  if (diff.inHours > 0) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
  return 'in ${diff.inMinutes}m';
}

String _relativeTime(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String _statsLine(FacebookPostRecord record) {
  String compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }

  final parts = <String>[
    if (record.impressions != null) '👁 ${compact(record.impressions!)}',
    if (record.reactions != null) '👍 ${compact(record.reactions!)}',
    if (record.clicks != null) '🔗 ${compact(record.clicks!)}',
  ];
  return parts.join(' · ');
}
