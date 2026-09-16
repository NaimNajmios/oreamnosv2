import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/vision_mode.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

import 'app_card.dart';

/// Modal bottom sheet for vision extraction: Camera/Gallery picker plus
/// Auto (cloud $0 chain -> on-device) vs On-device only toggle.
class OcrExtractionSheet extends StatelessWidget {
  const OcrExtractionSheet({
    super.key,
    required this.onSourceSelected,
    required this.visionMode,
    required this.onModeChanged,
  });

  final ValueChanged<ImageSource> onSourceSelected;
  final VisionMode visionMode;
  final ValueChanged<VisionMode> onModeChanged;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<ImageSource> onSourceSelected,
    required VisionMode visionMode,
    required ValueChanged<VisionMode> onModeChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => OcrExtractionSheet(
        onSourceSelected: onSourceSelected,
        visionMode: visionMode,
        onModeChanged: onModeChanged,
      ),
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
            visionMode == VisionMode.auto
                ? 'Auto tries free cloud vision first, then on-device OCR. Screenshots are sent to your configured AI provider.'
                : 'On-device only: unlimited, offline, nothing leaves your phone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<VisionMode>(
            segments: const [
              ButtonSegment(
                value: VisionMode.auto,
                label: Text('Auto'),
                icon: Icon(Icons.auto_awesome_outlined, size: 16),
              ),
              ButtonSegment(
                value: VisionMode.onDeviceOnly,
                label: Text('On-device'),
                icon: Icon(Icons.smartphone_outlined, size: 16),
              ),
            ],
            selected: {visionMode},
            onSelectionChanged: (s) {
              Haptics.lightImpact();
              onModeChanged(s.first);
            },
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
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
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
                      Icon(
                        Icons.photo_library_outlined,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
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
