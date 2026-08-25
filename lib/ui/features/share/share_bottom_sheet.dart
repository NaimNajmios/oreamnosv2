import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Modal bottom sheet presented when text or URL is shared to Oreamnos.
class ShareBottomSheet extends StatefulWidget {
  final String initialContent;

  const ShareBottomSheet({super.key, required this.initialContent});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  late String _selectedTone;

  @override
  void initState() {
    super.initState();
    _selectedTone = context.read<SettingsViewModel>().toneMode;
  }

  void _generate() {
    Haptics.mediumImpact();
    context.read<SettingsViewModel>().setToneMode(_selectedTone);
    context.read<GenerateViewModel>().setPendingInput(widget.initialContent);
    context.read<GenerateViewModel>().generatePost(widget.initialContent);
    Navigator.of(context).pop();

    final goRouter = GoRouter.of(context);
    if (goRouter.routeInformationProvider.value.uri.path != RoutePaths.generate) {
      goRouter.go(RoutePaths.generate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Share to Oreamnos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),

          // Content Preview Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: theme.colorScheme.surface,
            child: Text(
              widget.initialContent,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tone Selector
          Text(
            'Select Tone',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              AppChip(
                label: 'Formal',
                selected: _selectedTone == 'formal',
                onTap: () => setState(() => _selectedTone = 'formal'),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: 'Casual',
                selected: _selectedTone == 'casual',
                onTap: () => setState(() => _selectedTone = 'casual'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Primary Action
          AppButton(
            label: 'Curate Post Now',
            icon: Icons.auto_awesome_rounded,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }
}
