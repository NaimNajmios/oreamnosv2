import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'background_picker.dart';
import 'ratio_selector.dart';

class DesignDock extends StatefulWidget {
  final CardGeneratorViewModel viewModel;

  const DesignDock({super.key, required this.viewModel});

  @override
  State<DesignDock> createState() => _DesignDockState();
}

class _DesignDockState extends State<DesignDock> {
  late TextEditingController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    _badgeCtrl = TextEditingController(text: widget.viewModel.cardData?.microStat ?? '');
    widget.viewModel.addListener(_syncBadge);
  }

  void _syncBadge() {
    final v = widget.viewModel.cardData?.microStat ?? '';
    if (_badgeCtrl.text != v) {
      final hasFocus = FocusManager.instance.primaryFocus?.context?.widget is EditableText;
      if (!hasFocus) _badgeCtrl.text = v;
    }
  }

  @override
  void didUpdateWidget(covariant DesignDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_syncBadge);
      widget.viewModel.addListener(_syncBadge);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncBadge);
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Template — icon-only compact, tap expand control to show labels
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.md, AppSpacing.screenHorizontal, 0),
              child: Row(
                children: [
                  Text('TEMPLATE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Haptics.selectionClick();
                      vm.toggleTemplateCompact();
                    },
                    borderRadius: AppSpacing.borderRadiusPill,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppSpacing.borderRadiusPill,
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(vm.templateCompact ? 'Expand' : 'Compact', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                          const SizedBox(width: 4),
                          Icon(vm.templateCompact ? Icons.expand_more_rounded : Icons.expand_less_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: vm.templateCompact ? _buildCompactTemplates(vm) : _buildExpandedTemplates(vm),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.md, AppSpacing.screenHorizontal, 0),
              child: BackgroundPicker(
                image: vm.backgroundImage,
                scrim: vm.scrimOpacity,
                onScrimChanged: vm.setScrim,
                onPick: vm.pickImage,
                onRemove: vm.removeImage,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 0, AppSpacing.screenHorizontal, AppSpacing.md),
                title: Text('Advanced', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                subtitle: Text(
                  '${vm.selectedRatio.label} • ${vm.selectedFont == AppFont.defaultFont ? 'Inter' : vm.selectedFont == AppFont.classicSerif ? 'Lora' : 'Mono'} • ${(vm.headlineScale * 100).round()}%${vm.cardData?.hasMicroStat == true ? ' • Badge' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 11),
                ),
                children: [
                  Align(alignment: Alignment.centerLeft, child: RatioSelector(selected: vm.selectedRatio, onSelect: vm.setRatio)),
                  const SizedBox(height: AppSpacing.base),
                  // Typography
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TYPOGRAPHY', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppChip(label: 'Inter', selected: vm.selectedFont == AppFont.defaultFont, onTap: () => vm.setFont(AppFont.defaultFont)),
                            AppChip(label: 'Lora Serif', selected: vm.selectedFont == AppFont.classicSerif, onTap: () => vm.setFont(AppFont.classicSerif)),
                            AppChip(label: 'Space Mono', selected: vm.selectedFont == AppFont.typewriter, onTap: () => vm.setFont(AppFont.typewriter)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text('Size', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Slider(
                                value: vm.headlineScale,
                                min: 0.85,
                                max: 1.15,
                                divisions: 6,
                                label: '${(vm.headlineScale * 100).round()}%',
                                onChanged: vm.setHeadlineScale,
                              ),
                            ),
                            Text('${(vm.headlineScale * 100).round()}%', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: vm.headlineScale == 1.0 ? null : () => vm.setHeadlineScale(1.0),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                        Text('Auto-shrink keeps 60 chars visible; slider nudges base size.', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BADGE (optional)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _badgeCtrl,
                          maxLength: 24,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'e.g. Hat-trick • 90\'',
                            hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.outline)),
                            enabledBorder: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.7))),
                            focusedBorder: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            suffixIcon: _badgeCtrl.text.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: () { _badgeCtrl.clear(); vm.updateMicroStat(''); })
                                : null,
                          ),
                          onChanged: (v) => vm.updateMicroStat(v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTemplates(CardGeneratorViewModel vm) {
    // Icon-only — 4 compact chips, no word splitting
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _IconChip(icon: Icons.view_agenda_outlined, selected: vm.selectedTemplate == CardTemplate.standard, onTap: () => vm.setTemplate(CardTemplate.standard)),
        _IconChip(icon: Icons.format_quote_rounded, selected: vm.selectedTemplate == CardTemplate.headlineQuote, onTap: () => vm.setTemplate(CardTemplate.headlineQuote)),
        _IconChip(icon: Icons.emergency_rounded, selected: vm.selectedTemplate == CardTemplate.breakingNews, onTap: () => vm.setTemplate(CardTemplate.breakingNews)),
        _IconChip(icon: Icons.military_tech_outlined, selected: vm.selectedTemplate == CardTemplate.statBadge, onTap: () => vm.setTemplate(CardTemplate.statBadge)),
      ],
    );
  }

  Widget _buildExpandedTemplates(CardGeneratorViewModel vm) {
    // Icon + label — horizontal scroll so no split
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _LabelChip(label: 'Standard', icon: Icons.view_agenda_outlined, selected: vm.selectedTemplate == CardTemplate.standard, onTap: () => vm.setTemplate(CardTemplate.standard)),
          const SizedBox(width: AppSpacing.sm),
          _LabelChip(label: 'Quote', icon: Icons.format_quote_rounded, selected: vm.selectedTemplate == CardTemplate.headlineQuote, onTap: () => vm.setTemplate(CardTemplate.headlineQuote)),
          const SizedBox(width: AppSpacing.sm),
          _LabelChip(label: 'Breaking', icon: Icons.emergency_rounded, selected: vm.selectedTemplate == CardTemplate.breakingNews, onTap: () => vm.setTemplate(CardTemplate.breakingNews)),
          const SizedBox(width: AppSpacing.sm),
          _LabelChip(label: 'Stat', icon: Icons.military_tech_outlined, selected: vm.selectedTemplate == CardTemplate.statBadge, onTap: () => vm.setTemplate(CardTemplate.statBadge)),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _IconChip({required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { Haptics.selectionClick(); onTap(); },
        borderRadius: AppSpacing.borderRadiusPill,
        child: Container(
          width: 56,
          height: 36,
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outline, width: selected ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _LabelChip({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { Haptics.selectionClick(); onTap(); },
        borderRadius: AppSpacing.borderRadiusPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outline, width: selected ? 1.5 : 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
