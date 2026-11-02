import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Attachment slot for the compose screen.
///
/// Empty: Gallery / Camera buttons. Filled: 72px thumbnail with
/// Replace / Remove — the picked file is already downscaled ≤2048px / q85
/// by ImagePicker, so no extra processing happens here.
class ImageAttachmentTile extends StatelessWidget {
  const ImageAttachmentTile({
    super.key,
    required this.imagePath,
    required this.onAttachGallery,
    required this.onAttachCamera,
    required this.onRemove,
    required this.onReplace,
  });

  final String? imagePath;
  final VoidCallback onAttachGallery;
  final VoidCallback onAttachCamera;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return _AttachmentContainer(
      child: hasImage
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusSm,
                  child: Image.file(
                    File(imagePath!),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      size: 32,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Card attached',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Published as a photo post with the caption below',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onReplace, child: const Text('Replace')),
                IconButton(
                  tooltip: 'Remove attachment',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    Haptics.lightImpact();
                    onRemove();
                  },
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Haptics.lightImpact();
                      onAttachGallery();
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Haptics.lightImpact();
                      onAttachCamera();
                    },
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AttachmentContainer extends StatelessWidget {
  const _AttachmentContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}
