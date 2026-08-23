import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'app_card.dart';

/// Modal bottom sheet for choosing between Camera and Gallery OCR image extraction.
class OcrExtractionSheet extends StatelessWidget {
  const OcrExtractionSheet({
    super.key,
    required this.onSourceSelected,
  });

  final ValueChanged<ImageSource> onSourceSelected;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<ImageSource> onSourceSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => OcrExtractionSheet(onSourceSelected: onSourceSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Extract Text from Image',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Use on-device OCR machine learning to extract text from a photo or screenshot.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  onTap: () {
                    Haptics.lightImpact();
                    Navigator.of(context).pop();
                    onSourceSelected(ImageSource.camera);
                  },
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 28, color: theme.colorScheme.primary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Camera',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Take a photo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppCard(
                  onTap: () {
                    Haptics.lightImpact();
                    Navigator.of(context).pop();
                    onSourceSelected(ImageSource.gallery);
                  },
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 28, color: theme.colorScheme.primary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Gallery',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose screenshot',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
