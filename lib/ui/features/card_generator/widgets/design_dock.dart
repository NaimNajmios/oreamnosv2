import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'background_picker.dart';
import 'ratio_selector.dart';

class DesignDock extends StatelessWidget {
  final CardGeneratorViewModel viewModel;

  const DesignDock({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Text('TEMPLATE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Row(
                children: [
                  _TplChip(label: 'Standard', icon: Icons.view_agenda_outlined, selected: viewModel.selectedTemplate == CardTemplate.standard, onTap: () => viewModel.setTemplate(CardTemplate.standard)),
                  const SizedBox(width: AppSpacing.sm),
                  _TplChip(label: 'Quote', icon: Icons.format_quote_rounded, selected: viewModel.selectedTemplate == CardTemplate.headlineQuote, onTap: () => viewModel.setTemplate(CardTemplate.headlineQuote)),
                  const SizedBox(width: AppSpacing.sm),
                  _TplChip(label: 'Breaking', icon: Icons.emergency_rounded, selected: viewModel.selectedTemplate == CardTemplate.breakingNews, onTap: () => viewModel.setTemplate(CardTemplate.breakingNews)),
                  const SizedBox(width: AppSpacing.sm),
                  _TplChip(label: 'Stat', icon: Icons.military_tech_outlined, selected: viewModel.selectedTemplate == CardTemplate.statBadge, onTap: () => viewModel.setTemplate(CardTemplate.statBadge)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Background
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: BackgroundPicker(
                image: viewModel.backgroundImage,
                scrim: viewModel.scrimOpacity,
                vignette: viewModel.useVignette,
                onScrimChanged: viewModel.setScrim,
                onVignetteChanged: viewModel.setVignette,
                onPick: viewModel.pickImage,
                onRemove: viewModel.removeImage,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Ratio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: RatioSelector(
                selected: viewModel.selectedRatio,
                onSelect: viewModel.setRatio,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Typography
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Text('TYPOGRAPHY', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Row(
                children: [
                  AppChip(label: 'Inter', selected: viewModel.selectedFont == AppFont.defaultFont, onTap: () => viewModel.setFont(AppFont.defaultFont)),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(label: 'Lora Serif', selected: viewModel.selectedFont == AppFont.classicSerif, onTap: () => viewModel.setFont(AppFont.classicSerif)),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(label: 'Space Mono', selected: viewModel.selectedFont == AppFont.typewriter, onTap: () => viewModel.setFont(AppFont.typewriter)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TplChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TplChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppChip(label: label, icon: icon, selected: selected, onTap: onTap);
  }
}
