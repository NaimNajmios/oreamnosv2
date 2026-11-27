import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/card_export_format.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_outlined_button.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_mark.dart';

/// Modal sheet for exporting generated graphic cards.
class ExportBottomSheet extends StatefulWidget {
  const ExportBottomSheet({
    super.key,
    required this.onSaveToGallery,
    required this.onShare,
  });

  final Future<void> Function(CardExportFormat) onSaveToGallery;
  final Future<void> Function(CardExportFormat) onShare;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(CardExportFormat) onSaveToGallery,
    required Future<void> Function(CardExportFormat) onShare,
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
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  CardExportFormat _format = CardExportFormat.png;

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
            'Save a high-resolution card to the gallery or share it directly.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<CardExportFormat>(
            segments: CardExportFormat.values
                .map(
                  (format) =>
                      ButtonSegment(value: format, label: Text(format.label)),
                )
                .toList(),
            selected: {_format},
            onSelectionChanged: (value) =>
                setState(() => _format = value.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Save to Gallery',
            icon: Icons.download_rounded,
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.onSaveToGallery(_format);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppOutlinedButton(
            label: 'Share Image',
            icon: Icons.share_rounded,
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.onShare(_format);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const Center(child: KickoffDotsDivider()),
        ],
      ),
    );
  }
}
