import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';

/// Bottom action bar: post-now/schedule mode, progress, and the primary CTA.
class FacebookComposeActionBar extends StatelessWidget {
  const FacebookComposeActionBar({
    super.key,
    required this.draft,
    required this.pageName,
    required this.canPublish,
    required this.needsConnection,
    required this.onPost,
    required this.onModeChanged,
    required this.onPickSchedule,
  });

  final FacebookComposeState draft;
  final String pageName;
  final bool canPublish;
  final bool needsConnection;
  final VoidCallback onPost;
  final ValueChanged<FacebookPublishMode> onModeChanged;
  final VoidCallback onPickSchedule;

  static String _progressCopy(double progress, int count) {
    if (progress <= 0) {
      return count > 1 ? 'Preparing photos…' : 'Preparing photo…';
    }
    final percent = (progress * 100).round();
    if (count <= 1) return 'Uploading photo · $percent%';
    final index = (progress * count).ceil().clamp(1, count);
    return 'Uploading photo $index of $count · $percent%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = pageName.trim().isEmpty ? 'Facebook' : pageName;
    final progress = draft.uploadProgress;
    final scheduled = draft.publishMode == FacebookPublishMode.scheduled;
    final scheduledAt = draft.scheduledAt;
    final scheduleLabel = scheduledAt == null
        ? 'Choose date & time'
        : _formatSchedule(scheduledAt);

    final label = needsConnection
        ? 'Connect Page to post'
        : draft.isPreparing
        ? 'Preparing photos…'
        : draft.isPublishing
        ? (draft.media.length > 1
              ? 'Uploading photos…'
              : (draft.hasImage ? 'Uploading photo…' : 'Publishing…'))
        : scheduled
        ? 'Schedule for $scheduleLabel'
        : !draft.publishFeed && draft.storyEnabled
        ? 'Post Story'
        : draft.storyEnabled
        ? 'Post to $target + Story'
        : 'Post to $target';

    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((draft.isPublishing || draft.isPreparing) &&
              progress != null) ...[
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusPill,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              draft.isPreparing
                  ? 'Preparing photos…'
                  : _progressCopy(progress, draft.media.length),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: SegmentedButton<FacebookPublishMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: FacebookPublishMode.now,
                      label: Text('Post now'),
                      icon: Icon(Icons.send_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: FacebookPublishMode.scheduled,
                      label: Text('Schedule'),
                      icon: Icon(Icons.schedule_rounded, size: 16),
                    ),
                  ],
                  selected: {draft.publishMode},
                  onSelectionChanged: (selection) =>
                      onModeChanged(selection.first),
                ),
              ),
            ],
          ),
          if (scheduled) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onPickSchedule,
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text(scheduleLabel),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Device time · Facebook schedules at least 10 minutes ahead.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: label,
            isLoading: draft.isPublishing,
            onPressed: canPublish || needsConnection ? onPost : null,
            icon: scheduled ? Icons.schedule_rounded : Icons.public_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Publishes publicly as your Page. Markdown has been stripped.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatSchedule(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '${at.month}/${at.day} $h:$m';
  }
}
