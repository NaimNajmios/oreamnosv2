import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';

class BackgroundPicker extends StatelessWidget {
  final File? image;
  final double scrim;
  final ValueChanged<double> onScrimChanged;
  final Future<void> Function(ImageSource) onPick;
  final VoidCallback onRemove;

  const BackgroundPicker({
    super.key,
    required this.image,
    required this.scrim,
    required this.onScrimChanged,
    required this.onPick,
    required this.onRemove,
  });

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.md,
            AppSpacing.base,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Choose image source',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.base),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  Haptics.lightImpact();
                  onPick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  Haptics.lightImpact();
                  onPick(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppChip(
              label: image == null ? 'Pick image' : 'Change image',
              icon: Icons.image_outlined,
              onTap: () => _showSourceSheet(context),
            ),
            if (image != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: 'Remove',
                icon: Icons.close_rounded,
                onTap: () {
                  Haptics.lightImpact();
                  onRemove();
                },
              ),
            ],
          ],
        ),
        if (image != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Overlay',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              Text(
                '${(scrim * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
