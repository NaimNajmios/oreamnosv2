import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';

class BackgroundPicker extends StatelessWidget {
  final File? image;
  final double scrim;
  final bool vignette;
  final ValueChanged<double> onScrimChanged;
  final ValueChanged<bool> onVignetteChanged;
  final Future<void> Function(ImageSource) onPick;
  final VoidCallback onRemove;

  const BackgroundPicker({
    super.key,
    required this.image,
    required this.scrim,
    required this.vignette,
    required this.onScrimChanged,
    required this.onVignetteChanged,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BACKGROUND',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            AppChip(
              label: image == null ? 'Pick Image' : 'Change',
              icon: Icons.image_outlined,
              onTap: () => onPick(ImageSource.gallery),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Camera',
              icon: Icons.photo_camera_outlined,
              onTap: () => onPick(ImageSource.camera),
            ),
            if (image != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: 'Remove',
                icon: Icons.close_rounded,
                onTap: onRemove,
              ),
            ],
          ],
        ),
        if (image == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add a pitch or player photo — we overlay a dark scrim so text pops.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Overlay', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              Expanded(
                child: Slider(
                  value: scrim,
                  min: 0.3,
                  max: 0.75,
                  divisions: 9,
                  label: '${(scrim * 100).round()}%',
                  onChanged: onScrimChanged,
                ),
              ),
              Text('${(scrim * 100).round()}%', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
          Row(
            children: [
              Text('Vignette', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Switch(
                value: vignette,
                onChanged: onVignetteChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusSm,
            child: Stack(
              children: [
                Image.file(image!, height: 92, width: double.infinity, fit: BoxFit.cover),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: scrim), Colors.black.withValues(alpha: scrim * 0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Text('Preview scrim', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
