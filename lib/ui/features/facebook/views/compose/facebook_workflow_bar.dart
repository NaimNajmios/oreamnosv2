import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';

/// Compact summary of the active posting workflow.
class FacebookWorkflowBar extends StatelessWidget {
  const FacebookWorkflowBar({
    super.key,
    required this.draft,
    required this.onTap,
  });

  final FacebookComposeState draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = draft.workflowName.isNotEmpty
        ? draft.workflowName
        : draft.storyEnabled
        ? 'Page + Story'
        : 'Page post';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            draft.storyEnabled
                ? Icons.auto_stories_rounded
                : Icons.article_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            draft.publishFeed && draft.storyEnabled
                ? 'Page + Story'
                : draft.storyEnabled
                ? 'Story only'
                : 'Page only',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
