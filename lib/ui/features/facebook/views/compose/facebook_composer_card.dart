import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';

/// Caption editor, photo carousel, and media action row.
class FacebookComposerCard extends StatelessWidget {
  const FacebookComposerCard({
    super.key,
    required this.controller,
    required this.draft,
    required this.onGallery,
    required this.onCamera,
    required this.onHashtags,
    required this.onRemoveMedia,
    required this.onEditMedia,
  });

  final TextEditingController controller;
  final FacebookComposeState draft;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onHashtags;
  final ValueChanged<String> onRemoveMedia;
  final ValueChanged<FacebookMediaItem> onEditMedia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppSpacing.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.base),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.base,
              right: AppSpacing.base,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  '${draft.text.length} chars',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (draft.text.length > 125)
                  Flexible(
                    child: Text(
                      'Feed shows ~125, then See more',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (draft.media.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: ClipRRect(
                borderRadius: AppSpacing.borderRadiusMd,
                child: MediaCarousel(
                  media: draft.media,
                  onEdit: onEditMedia,
                  onRemove: onRemoveMedia,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Text(
                draft.media.length > 1
                    ? 'Swipe between photos · edit to crop, reorder or add alt text'
                    : 'Tap edit to crop, zoom or add alt text',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          ],
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: MediaActionBar(
              onGallery: onGallery,
              onCamera: onCamera,
              onHashtags: onHashtags,
              mediaCount: draft.media.length,
              canAddPhoto: draft.canAddMoreMedia,
            ),
          ),
        ],
      ),
    );
  }
}
