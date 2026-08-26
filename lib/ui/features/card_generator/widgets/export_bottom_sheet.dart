import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_outlined_button.dart';

/// Modal sheet for exporting generated graphic cards.
class ExportBottomSheet extends StatelessWidget {
  const ExportBottomSheet({
    super.key,
    required this.onSaveToGallery,
    required this.onShare,
  });

  final Future<void> Function() onSaveToGallery;
  final VoidCallback onShare;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onSaveToGallery,
    required VoidCallback onShare,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) =>
          ExportBottomSheet(onSaveToGallery: onSaveToGallery, onShare: onShare),
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
                  Icons.download_done_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Export Graphic Card',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Save high-resolution 4:5 image to gallery or share directly to social media.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save to Gallery',
            icon: Icons.download_rounded,
            onPressed: () async {
              Navigator.of(context).pop();
              await onSaveToGallery();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppOutlinedButton(
            label: 'Share Image',
            icon: Icons.share_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              onShare();
            },
          ),
        ],
      ),
    );
  }
}
