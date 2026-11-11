import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_ghost_button.dart';
import 'package:oreamnos/ui/core/widgets/app_outlined_button.dart';
import 'package:oreamnos/ui/features/facebook/utils/facebook_external_links.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';

/// Result panel shown after a post is published or scheduled.
///
/// Actions are real buttons (not text links): the filled primary is the main
/// next step, secondary utilities are outlined, and quiet actions are ghost.
class FacebookSuccessView extends StatelessWidget {
  const FacebookSuccessView({
    super.key,
    required this.draft,
    required this.pageName,
    required this.pagePictureUrl,
    required this.onView,
    required this.onCopy,
    required this.onCopyCaption,
    required this.onPublishAnother,
    required this.onDone,
    this.onCancelSchedule,
  });

  final FacebookComposeState draft;
  final String pageName;
  final String pagePictureUrl;
  final VoidCallback onView;
  final VoidCallback onCopy;
  final VoidCallback onCopyCaption;
  final VoidCallback onPublishAnother;
  final VoidCallback onDone;
  final VoidCallback? onCancelSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = pageName.trim().isEmpty ? 'your Page' : pageName;
    final scheduled = draft.isScheduled;
    final at = draft.scheduledAt;
    final permalink = draft.result?.permalink ?? '';
    final canOpenFeedPost = facebookPostUri(permalink) != null;
    final showCopyLink = !scheduled && canOpenFeedPost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.base,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              scheduled ? Icons.schedule_rounded : Icons.check_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            scheduled ? 'Post scheduled' : 'Your post is live',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            scheduled
                ? 'Will publish to $target on ${_formatSchedule(at)}'
                : draft.storyError != null
                ? 'Page post published to $target · Story failed'
                : draft.storyEnabled && draft.storyResult != null
                ? draft.publishFeed
                      ? 'Published to $target + Story'
                      : 'Published to Story'
                : 'Published to $target',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (draft.storyEnabled)
            Builder(
              builder: (rowContext) {
                final storyPublished = draft.storyResult != null;
                final row = Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        storyPublished
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 16,
                        color: storyPublished
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          storyPublished
                              ? 'Story published'
                              : 'Story failed: ${draft.storyError ?? 'unknown error'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: storyPublished
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ),
                      if (storyPublished && canOpenFeedPost) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                );
                if (!storyPublished) return row;
                return Semantics(
                  button: true,
                  label: canOpenFeedPost
                      ? 'Open the Facebook post for this Story'
                      : 'Story link unavailable',
                  child: InkWell(
                    borderRadius: AppSpacing.borderRadiusPill,
                    onTap: () {
                      if (canOpenFeedPost) {
                        onView();
                      } else {
                        ScaffoldMessenger.of(rowContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This Story has no feed post to open.',
                            ),
                          ),
                        );
                      }
                    },
                    child: row,
                  ),
                );
              },
            ),
          PostPreviewCard(
            pageName: pageName,
            pagePictureUrl: pagePictureUrl,
            message: draft.text,
            media: draft.media,
            imagePath: draft.imagePath,
            imageAspect: draft.imageAspect,
            imageZoom: draft.mediaItem?.zoom ?? 1.0,
            imageOffset: draft.mediaItem?.offset ?? Offset.zero,
            imageAltText: draft.mediaItem?.altText ?? '',
            maxMessageLines: 6,
          ),
          if (!scheduled && canOpenFeedPost)
            AppButton(
              label: 'View on Facebook',
              icon: Icons.open_in_new_rounded,
              onPressed: onView,
            ),
          Row(
            children: [
              if (showCopyLink) ...[
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Copy link',
                    icon: Icons.link_rounded,
                    height: 48,
                    onPressed: onCopy,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: AppOutlinedButton(
                  label: 'Copy caption',
                  icon: Icons.copy_rounded,
                  height: 48,
                  onPressed: onCopyCaption,
                ),
              ),
            ],
          ),
          if (scheduled && onCancelSchedule != null)
            AppOutlinedButton(
              label: 'Cancel schedule',
              icon: Icons.event_busy_rounded,
              height: 48,
              foregroundColor: theme.colorScheme.error,
              borderColor: theme.colorScheme.error,
              onPressed: onCancelSchedule,
            ),
          AppGhostButton(
            label: 'Publish another',
            icon: Icons.add_rounded,
            onPressed: onPublishAnother,
          ),
          AppButton(label: 'Done', onPressed: onDone),
        ],
      ),
    );
  }

  static String _formatSchedule(DateTime? at) {
    if (at == null) return 'a later time';
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '${at.month}/${at.day} $h:$m';
  }
}
