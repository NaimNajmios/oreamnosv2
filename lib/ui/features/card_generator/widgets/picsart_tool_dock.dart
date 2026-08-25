import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'background_picker.dart';
import 'ratio_selector.dart';

enum PicsartPanel { templates, ratio, background, typography, text }

class PicsartToolDock extends StatefulWidget {
  final CardGeneratorViewModel viewModel;

  const PicsartToolDock({super.key, required this.viewModel});

  @override
  State<PicsartToolDock> createState() => _PicsartToolDockState();
}

class _PicsartToolDockState extends State<PicsartToolDock> {
  PicsartPanel? _activePanel;

  // Text controllers for the text panel
  late TextEditingController _headlineCtrl;
  late TextEditingController _subtextCtrl;
  late TextEditingController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.viewModel.cardData;
    _headlineCtrl = TextEditingController(text: d?.headline ?? '');
    _subtextCtrl = TextEditingController(text: d?.subtext ?? '');
    _badgeCtrl = TextEditingController(text: d?.microStat ?? '');
    widget.viewModel.addListener(_syncText);
  }

  void _syncText() {
    final d = widget.viewModel.cardData;
    if (d == null) return;
    final hasFocus = FocusManager.instance.primaryFocus?.context?.widget is EditableText;
    if (!hasFocus) {
      if (_headlineCtrl.text != d.headline) _headlineCtrl.text = d.headline;
      if (_subtextCtrl.text != d.subtext) _subtextCtrl.text = d.subtext;
      if (_badgeCtrl.text != d.microStat) _badgeCtrl.text = d.microStat ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant PicsartToolDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_syncText);
      widget.viewModel.addListener(_syncText);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncText);
    _headlineCtrl.dispose();
    _subtextCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  void _setPanel(PicsartPanel? panel) {
    Haptics.selectionClick();
    setState(() {
      _activePanel = panel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _activePanel == null
              ? _buildMainToolbar(theme)
              : _buildActivePanel(theme),
        ),
      ),
    );
  }

  Widget _buildMainToolbar(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _ToolItem(
            icon: Icons.view_carousel_outlined,
            label: 'Templates',
            onTap: () => _setPanel(PicsartPanel.templates),
          ),
          _ToolItem(
            icon: Icons.crop_outlined,
            label: 'Ratio',
            onTap: () => _setPanel(PicsartPanel.ratio),
          ),
          _ToolItem(
            icon: Icons.image_outlined,
            label: 'Background',
            onTap: () => _setPanel(PicsartPanel.background),
          ),
          _ToolItem(
            icon: Icons.text_format_outlined,
            label: 'Typography',
            onTap: () => _setPanel(PicsartPanel.typography),
          ),
          _ToolItem(
            icon: Icons.edit_note_outlined,
            label: 'Text',
            onTap: () => _setPanel(PicsartPanel.text),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePanel(ThemeData theme) {
    Widget content;
    String title = '';
    
    switch (_activePanel!) {
      case PicsartPanel.templates:
        title = 'Templates';
        content = _buildTemplatesPanel(theme);
        break;
      case PicsartPanel.ratio:
        title = 'Ratio';
        content = _buildRatioPanel(theme);
        break;
      case PicsartPanel.background:
        title = 'Background';
        content = _buildBackgroundPanel(theme);
        break;
      case PicsartPanel.typography:
        title = 'Typography';
        content = _buildTypographyPanel(theme);
        break;
      case PicsartPanel.text:
        title = 'Edit Text';
        content = _buildTextPanel(theme);
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel Header
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => _setPanel(null),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: () => _setPanel(null),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Panel Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesPanel(ThemeData theme) {
    final vm = widget.viewModel;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        _TemplateChip(
          label: 'Standard',
          icon: Icons.view_agenda_outlined,
          selected: vm.selectedTemplate == CardTemplate.standard,
          onTap: () => vm.setTemplate(CardTemplate.standard),
        ),
        _TemplateChip(
          label: 'Quote',
          icon: Icons.format_quote_rounded,
          selected: vm.selectedTemplate == CardTemplate.headlineQuote,
          onTap: () => vm.setTemplate(CardTemplate.headlineQuote),
        ),
        _TemplateChip(
          label: 'Breaking',
          icon: Icons.emergency_rounded,
          selected: vm.selectedTemplate == CardTemplate.breakingNews,
          onTap: () => vm.setTemplate(CardTemplate.breakingNews),
        ),
        _TemplateChip(
          label: 'Stat',
          icon: Icons.military_tech_outlined,
          selected: vm.selectedTemplate == CardTemplate.statBadge,
          onTap: () => vm.setTemplate(CardTemplate.statBadge),
        ),
      ],
    );
  }

  Widget _buildRatioPanel(ThemeData theme) {
    return Align(
      alignment: Alignment.center,
      child: RatioSelector(
        selected: widget.viewModel.selectedRatio,
        onSelect: widget.viewModel.setRatio,
      ),
    );
  }

  Widget _buildBackgroundPanel(ThemeData theme) {
    final vm = widget.viewModel;
    return Column(
      children: [
        BackgroundPicker(
          image: vm.backgroundImage,
          scrim: vm.scrimOpacity,
          onScrimChanged: vm.setScrim,
          onPick: vm.pickImage,
          onRemove: vm.removeImage,
        ),
        if (vm.hasImage && vm.extractedPalette != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.palette_outlined, size: 16),
              const SizedBox(width: 6),
              Text('Auto-Extract Palette', style: theme.textTheme.labelMedium),
              const SizedBox(width: 16),
              Switch.adaptive(
                value: vm.useAutoPalette,
                onChanged: (v) {
                  Haptics.selectionClick();
                  vm.setAutoPalette(v);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTypographyPanel(ThemeData theme) {
    final vm = widget.viewModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(label: 'Inter', selected: vm.selectedFont == AppFont.defaultFont, onTap: () => vm.setFont(AppFont.defaultFont)),
            AppChip(label: 'Lora Serif', selected: vm.selectedFont == AppFont.classicSerif, onTap: () => vm.setFont(AppFont.classicSerif)),
            AppChip(label: 'Space Mono', selected: vm.selectedFont == AppFont.typewriter, onTap: () => vm.setFont(AppFont.typewriter)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('Size', style: theme.textTheme.labelMedium),
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
            Text('${(vm.headlineScale * 100).round()}%', style: theme.textTheme.labelMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildTextPanel(ThemeData theme) {
    final vm = widget.viewModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          controller: _headlineCtrl,
          label: 'Headline — max 60',
          maxLen: 60,
          maxLines: 2,
          onChanged: (v) => vm.updateHeadline(v),
        ),
        const SizedBox(height: AppSpacing.md),
        _Field(
          controller: _subtextCtrl,
          label: 'Hook — one sentence, max 90',
          maxLen: 90,
          maxLines: 2,
          onChanged: (v) => vm.updateSubtext(v),
        ),
        const SizedBox(height: AppSpacing.md),
        _Field(
          controller: _badgeCtrl,
          label: 'Badge (Optional) — max 24',
          maxLen: 24,
          maxLines: 1,
          onChanged: (v) => vm.updateMicroStat(v),
        ),
      ],
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.onSurface),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { Haptics.selectionClick(); onTap(); },
        borderRadius: AppSpacing.borderRadiusPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outline, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLen;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.maxLen,
    required this.maxLines,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLength: maxLen,
      maxLines: maxLines,
      minLines: 1,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.7))),
        focusedBorder: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      onChanged: onChanged,
    );
  }
}
