import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_draft_store.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

/// Saved drafts: open, duplicate, delete. Autosave keeps the active draft up
/// to date, including its photos (copied into app documents).
class FacebookDraftsScreen extends ConsumerStatefulWidget {
  const FacebookDraftsScreen({super.key});

  @override
  ConsumerState<FacebookDraftsScreen> createState() =>
      _FacebookDraftsScreenState();
}

class _FacebookDraftsScreenState extends ConsumerState<FacebookDraftsScreen> {
  List<FacebookDraftRecord> _drafts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<FacebookDraftStore>().pruneOrphans();
    });
  }

  Future<void> _load() async {
    await ref.read(facebookDraftProvider.notifier).saveDraftNow();
    if (!mounted) return;
    setState(() {
      _drafts = getIt<FacebookDraftStore>().loadAll();
      _loading = false;
    });
  }

  Future<void> _open(FacebookDraftRecord record) async {
    final opened = await ref
        .read(facebookDraftProvider.notifier)
        .openDraft(record.id);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That draft could not be opened.')),
      );
      return;
    }
    await context.push(RoutePaths.facebookCompose);
    if (mounted) _load();
  }

  Future<void> _newDraft() async {
    final store = getIt<FacebookDraftStore>();
    final existing = store.loadAll();
    if (existing.length >= FacebookDraftStore.maxDrafts) {
      final oldest = existing.last;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Draft limit reached'),
          content: Text(
            'Keep at most ${FacebookDraftStore.maxDrafts} drafts. Delete '
            '"${_draftLabel(oldest)}" to create a new one?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete oldest'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await ref.read(facebookDraftProvider.notifier).deleteDraft(oldest.id);
      if (!mounted) return;
    }
    ref.read(facebookDraftProvider.notifier).startEmptyDraft();
    await context.push(RoutePaths.facebookCompose);
    if (mounted) _load();
  }

  static String _draftLabel(FacebookDraftRecord record) {
    final text = record.text.trim();
    if (text.isNotEmpty) {
      final first = text.split('\n').first;
      return first.length > 40 ? '${first.substring(0, 40)}…' : first;
    }
    return record.media.isEmpty ? 'Empty draft' : 'Photo draft';
  }

  Future<void> _duplicate(FacebookDraftRecord record) async {
    final id = await getIt<FacebookDraftStore>().duplicate(record.id);
    if (!mounted) return;
    Haptics.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          id == null ? 'Could not duplicate draft' : 'Draft duplicated',
        ),
      ),
    );
    _load();
  }

  Future<bool> _confirmDelete(FacebookDraftRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete draft?'),
        content: const Text(
          'The caption and photos in this draft will be removed from this '
          'device. Published posts are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(FacebookDraftRecord record) async {
    await ref.read(facebookDraftProvider.notifier).deleteDraft(record.id);
    _load();
  }

  Future<void> _showActions(FacebookDraftRecord record) async {
    Haptics.lightImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, size: 20),
              title: const Text('Open'),
              onTap: () => Navigator.pop(sheetContext, 'open'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, size: 20),
              title: const Text('Duplicate'),
              onTap: () => Navigator.pop(sheetContext, 'duplicate'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'open':
        await _open(record);
        break;
      case 'duplicate':
        await _duplicate(record);
        break;
      case 'delete':
        if (await _confirmDelete(record)) await _delete(record);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Drafts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newDraft,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New post'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
          ? EmptyState(
              icon: Icons.drafts_outlined,
              title: 'No drafts yet',
              description:
                  'Start a post and choose Save draft when you leave the '
                  'composer. Drafts keep their photos even after a restart.',
              actionLabel: 'Create a post',
              onAction: _newDraft,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.xxl * 2,
                ),
                itemCount: _drafts.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final record = _drafts[index];
                  return Dismissible(
                    key: ValueKey(record.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(record),
                    onDismissed: (_) => _delete(record),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.base),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    child: _DraftCard(
                      record: record,
                      onTap: () => _open(record),
                      onLongPress: () => _showActions(record),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.record,
    required this.onTap,
    required this.onLongPress,
  });

  final FacebookDraftRecord record;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoCount = record.media.length;
    final caption = record.text.trim().isEmpty
        ? (photoCount > 0 ? 'Photo post' : 'Empty draft')
        : record.text.trim().split('\n').first;
    final pageName = record.pageName.trim().isEmpty
        ? 'No Page selected'
        : record.pageName;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _DraftThumbnail(record: record),
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
                  const SizedBox(height: 4),
                  Text(
                    [
                      pageName,
                      if (photoCount > 0)
                        '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
                      _relativeTime(record.updatedAt),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (record.mode == 'scheduled' && record.scheduledAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Scheduled draft · ${_formatDate(record.scheduledAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
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
      ),
    );
  }

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return _formatDate(at);
  }

  static String _formatDate(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '${at.month}/${at.day} $h:$m';
  }
}

class _DraftThumbnail extends StatelessWidget {
  const _DraftThumbnail({required this.record});

  final FacebookDraftRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = record.media.isEmpty
        ? ''
        : (record.media.first['path'] ?? '').toString();
    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusMd,
      child: SizedBox(
        width: 56,
        height: 56,
        child: path.isEmpty
            ? _placeholder(theme)
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: 112,
                errorBuilder: (context, error, stack) => _placeholder(theme),
              ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.notes_rounded,
        size: 22,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
