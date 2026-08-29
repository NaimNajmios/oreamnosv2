import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_state.dart';

import 'background_picker.dart';
import 'ratio_selector.dart';

enum PicsartPanel { templates, ratio, background, typography, text, branding }

class PicsartToolDock extends ConsumerStatefulWidget {
  const PicsartToolDock({super.key});

  @override
  ConsumerState<PicsartToolDock> createState() => _PicsartToolDockState();
}

class _PicsartToolDockState extends ConsumerState<PicsartToolDock> {
  late TextEditingController _headlineCtrl;
  late TextEditingController _subtextCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _brandNameCtrl;
  late TextEditingController _brandHandleCtrl;
  late TextEditingController _watermarkCtrl;

  late FocusNode _headlineFocus;
  late FocusNode _subtextFocus;
  late FocusNode _badgeFocus;

  @override
  void initState() {
    super.initState();
    _headlineCtrl = TextEditingController();
    _subtextCtrl = TextEditingController();
    _badgeCtrl = TextEditingController();
    _brandNameCtrl = TextEditingController();
    _brandHandleCtrl = TextEditingController();
    _watermarkCtrl = TextEditingController();

    _headlineFocus = FocusNode();
    _subtextFocus = FocusNode();
    _badgeFocus = FocusNode();
  }

  void _syncText(CardGeneratorState state) {
    final d = state.cardData;
    final hasFocus =
        FocusManager.instance.primaryFocus?.context?.widget is EditableText;
    if (!hasFocus) {
      if (d != null) {
        if (_headlineCtrl.text != d.headline) _headlineCtrl.text = d.headline;
        if (_subtextCtrl.text != d.subtext) _subtextCtrl.text = d.subtext;
        if (_badgeCtrl.text != d.microStat) _badgeCtrl.text = d.microStat ?? '';
      }
      if (_brandNameCtrl.text != (state.brandName ?? '')) {
        _brandNameCtrl.text = state.brandName ?? '';
      }
      if (_brandHandleCtrl.text != (state.brandHandle ?? '')) {
        _brandHandleCtrl.text = state.brandHandle ?? '';
      }
      if (_watermarkCtrl.text != (state.watermarkText ?? '')) {
        _watermarkCtrl.text = state.watermarkText ?? '';
      }
    }

    if (state.focusedField == 'headline') {
      _headlineFocus.requestFocus();
      ref.read(cardGeneratorViewModelProvider.notifier).setFocusedField(null);
    } else if (state.focusedField == 'subtext') {
      _subtextFocus.requestFocus();
      ref.read(cardGeneratorViewModelProvider.notifier).setFocusedField(null);
    } else if (state.focusedField == 'microStat') {
      _badgeFocus.requestFocus();
      ref.read(cardGeneratorViewModelProvider.notifier).setFocusedField(null);
    }
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _subtextCtrl.dispose();
    _badgeCtrl.dispose();
    _brandNameCtrl.dispose();
    _brandHandleCtrl.dispose();
    _watermarkCtrl.dispose();
    _headlineFocus.dispose();
    _subtextFocus.dispose();
    _badgeFocus.dispose();
    super.dispose();
  }

  void _setPanel(String? panel) {
    Haptics.selectionClick();
    ref.read(cardGeneratorViewModelProvider.notifier).setActivePanel(panel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen(cardGeneratorViewModelProvider, (_, next) {
      _syncText(next);
    });

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
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
          child: ref.watch(cardGeneratorViewModelProvider).activePanel == null
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
            onTap: () => _setPanel('templates'),
          ),
          _ToolItem(
            icon: Icons.crop_outlined,
            label: 'Ratio',
            onTap: () => _setPanel('ratio'),
          ),
          _ToolItem(
            icon: Icons.image_outlined,
            label: 'Background',
            onTap: () => _setPanel('background'),
          ),
          _ToolItem(
            icon: Icons.text_format_outlined,
            label: 'Typography',
            onTap: () => _setPanel('typography'),
          ),
          _ToolItem(
            icon: Icons.edit_note_outlined,
            label: 'Text',
            onTap: () => _setPanel('text'),
          ),
          _ToolItem(
            icon: Icons.branding_watermark_outlined,
            label: 'Branding',
            onTap: () => _setPanel('branding'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePanel(ThemeData theme) {
    Widget content;
    String title = '';

    switch (ref.watch(cardGeneratorViewModelProvider).activePanel) {
      case 'templates':
        title = 'Templates';
        content = _buildTemplatesPanel(theme);
        break;
      case 'ratio':
        title = 'Ratio';
        content = _buildRatioPanel(theme);
        break;
      case 'background':
        title = 'Background';
        content = _buildBackgroundPanel(theme);
        break;
      case 'typography':
        title = 'Typography';
        content = _buildTypographyPanel(theme);
        break;
      case 'text':
        title = 'Edit Text';
        content = _buildTextPanel(theme);
        break;
      case 'branding':
        title = 'Branding & Watermark';
        content = _buildBrandingPanel(theme);
        break;
      default:
        content = const SizedBox();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: Column(
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
      ),
    );
  }

  Widget _buildTemplatesPanel(ThemeData theme) {
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            for (final t in CardTemplate.all) ...[
              _TemplateChip(
                label: t.displayName,
                icon: _iconFor(t),
                selected: state.selectedTemplate == t,
                onTap: () => notifier.setTemplate(t),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(CardTemplate t) {
    switch (t) {
      case CardTemplate.playerSpotlight:
        return Icons.person_outline_rounded;
      case CardTemplate.headlineQuote:
        return Icons.format_quote_rounded;
      case CardTemplate.topStats:
        return Icons.bar_chart_rounded;
      case CardTemplate.transferNews:
        return Icons.swap_horiz_rounded;
      case CardTemplate.breakingNews:
        return Icons.emergency_rounded;
      case CardTemplate.matchPreview:
        return Icons.sports_soccer_rounded;
      case CardTemplate.detailedScoreboard:
        return Icons.scoreboard_rounded;
      case CardTemplate.onThisDay:
        return Icons.history_rounded;
      case CardTemplate.startingXI:
        return Icons.groups_rounded;
      case CardTemplate.matchStatsComparison:
        return Icons.compare_rounded;
      case CardTemplate.socialPost:
        return Icons.share_rounded;
      case CardTemplate.rivalry:
        return Icons.people_rounded;
      case CardTemplate.tableStandings:
        return Icons.leaderboard_rounded;
      case CardTemplate.injuryReport:
        return Icons.healing_rounded;
      case CardTemplate.contractExpiry:
        return Icons.description_rounded;
      case CardTemplate.awardNominee:
        return Icons.military_tech_rounded;
      case CardTemplate.freeform:
        return Icons.format_shapes_rounded;
    }
  }

  Widget _buildRatioPanel(ThemeData theme) {
    return Align(
      alignment: Alignment.center,
      child: RatioSelector(
        selected: ref.watch(cardGeneratorViewModelProvider).selectedRatio,
        onSelect: ref.read(cardGeneratorViewModelProvider.notifier).setRatio,
      ),
    );
  }

  Widget _buildBackgroundPanel(ThemeData theme) {
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);
    return Column(
      children: [
        BackgroundPicker(
          image: state.backgroundImage,
          scrim: state.scrimOpacity,
          onScrimChanged: notifier.setScrim,
          onPick: notifier.pickImage,
          onRemove: notifier.removeImage,
        ),
        if (state.hasImage && state.extractedPalette != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<ImagePosition>(
                value: state.imagePosition,
                onChanged: (v) {
                  if (v != null) notifier.setImagePosition(v);
                },
                items: ImagePosition.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
              ),
              DropdownButton<PhotoFilter>(
                value: state.photoFilter,
                onChanged: (v) {
                  if (v != null) notifier.setPhotoFilter(v);
                },
                items: PhotoFilter.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.palette_outlined, size: 16),
              const SizedBox(width: 6),
              Text('Auto-Extract Palette', style: theme.textTheme.labelMedium),
              const SizedBox(width: 16),
              AppSwitch(
                value: state.useAutoPalette,
                onChanged: (v) => notifier.setAutoPalette(v),
              ),
            ],
          ),
        ] else if (!state.hasImage) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Solid Background', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                [
                  Colors.black,
                  Colors.white,
                  Colors.blue[900]!,
                  Colors.red[900]!,
                  Colors.green[900]!,
                  Colors.purple[900]!,
                  Colors.orange[900]!,
                  Colors.grey[900]!,
                ].map((color) {
                  final isSelected = state.extractedPalette?.first == color;
                  return GestureDetector(
                    onTap: () => notifier.setSolidBackgroundColor(color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.amberAccent
                              : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTypographyPanel(ThemeData theme) {
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(
              label: 'Inter',
              selected: state.selectedFont == AppFont.defaultFont,
              onTap: () => notifier.setFont(AppFont.defaultFont),
            ),
            AppChip(
              label: 'Lora Serif',
              selected: state.selectedFont == AppFont.classicSerif,
              onTap: () => notifier.setFont(AppFont.classicSerif),
            ),
            AppChip(
              label: 'Space Mono',
              selected: state.selectedFont == AppFont.typewriter,
              onTap: () => notifier.setFont(AppFont.typewriter),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('Size', style: theme.textTheme.labelMedium),
            Expanded(
              child: Slider(
                value: state.headlineScale,
                min: 0.85,
                max: 1.15,
                divisions: 6,
                label: '${(state.headlineScale * 100).round()}%',
                onChanged: notifier.setHeadlineScale,
              ),
            ),
            Text(
              '${(state.headlineScale * 100).round()}%',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextPanel(ThemeData theme) {
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    if (state.cardData == null) return const SizedBox();

    final json = state.cardData!.toJson();
    final stringFields = json.entries
        .where((e) => e.value is String && e.key != 'runtimeType')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: FilledButton.tonalIcon(
            onPressed: state.isExtracting
                ? null
                : () async {
                    await notifier.regenerateAllFields();
                  },
            icon: state.isExtracting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              state.isExtracting ? 'Regenerating...' : 'Regenerate All Fields',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
          ),
        ),
        ...stringFields.map((entry) {
          return _DynamicField(
            key: ValueKey('${state.cardData!.runtimeType}_${entry.key}'),
            fieldKey: entry.key,
            initialValue: entry.value as String,
            onChanged: (v) => notifier.updateCardField(entry.key, v),
            isRewriting: state.isRewriting(entry.key),
            onRewrite: () async {
              final brief = state.brief;
              if (brief == null) return;
              final prefs = getIt<PreferencesService>();
              final apiKey = await prefs.getApiKey(brief.provider);
              if (apiKey == null || apiKey.isEmpty) return;
              notifier.rewriteDynamicField(
                fieldKey: entry.key,
                provider: brief.provider,
                modelId: brief.modelId,
                apiKey: apiKey,
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildBrandingPanel(ThemeData theme) {
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _brandNameCtrl,
          decoration: InputDecoration(
            labelText: 'Brand / Account Name',
            hintText: 'e.g. Premier Central',
            border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm),
            isDense: true,
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
          ),
          onChanged: notifier.setBrandName,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _brandHandleCtrl,
          decoration: InputDecoration(
            labelText: 'Brand Handle',
            hintText: 'e.g. @premiercentral',
            border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm),
            isDense: true,
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
          ),
          onChanged: notifier.setBrandHandle,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show Card Brand Footer', style: theme.textTheme.titleSmall),
            AppSwitch(
              value: state.showBrandFooter,
              onChanged: notifier.setShowBrandFooter,
            ),
          ],
        ),
        const Divider(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show Corner Watermark', style: theme.textTheme.titleSmall),
            AppSwitch(
              value: state.showWatermark,
              onChanged: notifier.setShowWatermark,
            ),
          ],
        ),
        if (state.showWatermark) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _watermarkCtrl,
            decoration: InputDecoration(
              labelText: 'Watermark Text',
              hintText: '@yourhandle',
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              isDense: true,
              prefixIcon: const Icon(
                Icons.branding_watermark_outlined,
                size: 20,
              ),
            ),
            onChanged: notifier.setWatermarkText,
          ),
        ],
      ],
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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

  const _TemplateChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.selectionClick();
          onTap();
        },
        borderRadius: AppSpacing.borderRadiusPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
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
  final VoidCallback? onRewrite;
  final bool isRewriting;

  const _Field({
    required this.controller,
    required this.label,
    required this.maxLen,
    required this.maxLines,
    required this.onChanged,
    this.onRewrite,
    this.isRewriting = false,
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
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        suffixIcon: onRewrite == null
            ? null
            : isRewriting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                tooltip: 'AI Polish',
                onPressed: onRewrite,
              ),
      ),
      onChanged: onChanged,
    );
  }
}

class _DynamicField extends StatefulWidget {
  final String fieldKey;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onRewrite;
  final bool isRewriting;

  const _DynamicField({
    super.key,
    required this.fieldKey,
    required this.initialValue,
    required this.onChanged,
    required this.onRewrite,
    required this.isRewriting,
  });

  @override
  State<_DynamicField> createState() => _DynamicFieldState();
}

class _DynamicFieldState extends State<_DynamicField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue == 'N/A' ? '' : widget.initialValue,
    );
  }

  @override
  void didUpdateWidget(_DynamicField old) {
    super.didUpdateWidget(old);
    final newVal = widget.initialValue == 'N/A' ? '' : widget.initialValue;
    if (_ctrl.text != newVal && !FocusScope.of(context).hasFocus) {
      _ctrl.text = newVal;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Capitalize fieldKey for label
    final label =
        widget.fieldKey.substring(0, 1).toUpperCase() +
        widget.fieldKey
            .substring(1)
            .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _Field(
        controller: _ctrl,
        label: label,
        maxLen: 120,
        maxLines: 2,
        onChanged: widget.onChanged,
        isRewriting: widget.isRewriting,
        onRewrite: widget.onRewrite,
      ),
    );
  }
}
