import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/facebook_comment.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_comments_view_model.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';

/// Live comment moderation for one published post.
class FacebookCommentsScreen extends StatefulWidget {
  const FacebookCommentsScreen({
    super.key,
    required this.postId,
    this.postSnippet = '',
  });

  final String postId;
  final String postSnippet;

  @override
  State<FacebookCommentsScreen> createState() => _FacebookCommentsScreenState();
}

class _FacebookCommentsScreenState extends State<FacebookCommentsScreen> {
  late final FacebookCommentsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FacebookCommentsController(postId: widget.postId);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reply(FacebookComment comment) async {
    final controller = TextEditingController();
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.base + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reply to ${comment.authorName}',
                style: Theme.of(sheetContext).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a reply',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Post reply',
                onPressed: () =>
                    Navigator.of(sheetContext).pop(controller.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty || !mounted) return;
    final error = await _controller.reply(comment, message);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Reply posted')));
  }

  Future<void> _toggleHidden(FacebookComment comment) async {
    final error = await _controller.toggleHidden(comment);
    if (!mounted) return;
    if (error == null) Haptics.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (comment.isHidden ? 'Comment unhidden' : 'Comment hidden'),
        ),
      ),
    );
  }

  Future<void> _delete(FacebookComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this comment?'),
        content: const Text('This cannot be undone.'),
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
    if (confirmed != true || !mounted) return;
    final error = await _controller.delete(comment);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Comment deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (widget.postSnippet.isNotEmpty)
              Text(
                widget.postSnippet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          if (widget.postId.isEmpty) {
            return const Center(child: Text('No post selected.'));
          }
          if (state.loading && state.comments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.comments.isEmpty) {
            return _ErrorState(
              message: state.error!,
              needsReconnect: state.needsReconnect,
              permissionDenied: state.permissionDenied,
              onRetry: _controller.load,
              onReconnect: () => FacebookConnectionDialog.show(context),
            );
          }
          if (state.comments.isEmpty) {
            return RefreshIndicator(
              onRefresh: _controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No comments yet.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: state.comments.length + 1,
              separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                if (index == state.comments.length) {
                  return _footer(state);
                }
                final comment = state.comments[index];
                return _CommentTile(
                  comment: comment,
                  onReply: () => _reply(comment),
                  onToggleHidden: () => _toggleHidden(comment),
                  onDelete: () => _delete(comment),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _footer(FacebookCommentsState state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.base),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Center(
          child: TextButton(
            onPressed: _controller.loadMore,
            child: const Text('Load more comments'),
          ),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.base);
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.onToggleHidden,
    required this.onDelete,
  });

  final FacebookComment comment;
  final VoidCallback onReply;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = comment.authorName.trim().isEmpty
        ? '?'
        : comment.authorName.trim().characters.first.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initial,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                comment.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (comment.createdAt != null)
              Text(
                _relativeTime(comment.createdAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(comment.message, style: theme.textTheme.bodyMedium),
        if (comment.isHidden)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppSpacing.borderRadiusPill,
              ),
              child: Text(
                'Hidden',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            TextButton(onPressed: onReply, child: const Text('Reply')),
            if (comment.canHide)
              TextButton(
                onPressed: onToggleHidden,
                child: Text(comment.isHidden ? 'Unhide' : 'Hide'),
              ),
            if (comment.canRemove)
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            if (comment.replyCount > 0)
              Text(
                '${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${at.month}/${at.day}';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.needsReconnect,
    required this.permissionDenied,
    required this.onRetry,
    required this.onReconnect,
  });

  final String message;
  final bool needsReconnect;
  final bool permissionDenied;
  final VoidCallback onRetry;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.base),
            AppButton(
              label: (needsReconnect || permissionDenied)
                  ? 'Reconnect Page'
                  : 'Try again',
              onPressed: (needsReconnect || permissionDenied)
                  ? onReconnect
                  : onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
