import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/card_field.dart';
import 'package:oreamnos/domain/models/card_field_registry.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_state.dart';

import 'background_picker.dart';
import 'ratio_selector.dart';
import 'template_picker_grid.dart';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: AppMotion.transitionSpec,
              curve: AppMotion.curveTransition,
              child: AnimatedSwitcher(
                duration: AppMotion.transitionSpec,
                switchInCurve: AppMotion.curveTransition,
                switchOutCurve: AppMotion.curveTransition,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(
                    ref.watch(cardGeneratorViewModelProvider).activePanel ??
                        'none',
                  ),
                  child:
                      ref.watch(cardGeneratorViewModelProvider).activePanel !=
                          null
                      ? _buildActivePanel(theme)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            _buildMainToolbar(theme),
          ],
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
            padding: const EdgeInsets.only(left: 16, right: 8, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TemplatePickerGrid(
          selected: state.selectedTemplate,
          onSelect: (t) {
            Haptics.selectionClick();
            notifier.setTemplate(t);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.shuffle_rounded, size: 18),
          label: const Text('Surprise Me'),
          onPressed: () {
            Haptics.mediumImpact();
            notifier.shuffleDesign();
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
        ),
      ],
    );
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Opacity', style: theme.textTheme.labelSmall),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    Haptics.selectionClick();
                    notifier.setImageOpacity(1.0);
                  },
                  child: Slider(
                    value: state.imageOpacity,
                    min: 0.2,
                    max: 1.0,
                    divisions: 8,
                    label: '${(state.imageOpacity * 100).round()}%',
                    onChanged: notifier.setImageOpacity,
                    onChangeEnd: (_) => Haptics.selectionClick(),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text('Blur', style: theme.textTheme.labelSmall),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    Haptics.selectionClick();
                    notifier.setBackgroundBlurRadius(0.0);
                  },
                  child: Slider(
                    value: state.backgroundBlurRadius,
                    min: 0,
                    max: 25,
                    divisions: 5,
                    label: '${state.backgroundBlurRadius.round()}',
                    onChanged: notifier.setBackgroundBlurRadius,
                    onChangeEnd: (_) => Haptics.selectionClick(),
                  ),
                ),
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
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                  theme.colorScheme.error,
                  theme.colorScheme.surface,
                  theme.colorScheme.onSurface,
                  Colors.black,
                  Colors.white,
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
          TextField(
            decoration: InputDecoration(
              labelText: 'Badge Text',
              hintText: 'e.g. LIVE, NEW',
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              isDense: true,
            ),
            controller: TextEditingController(text: state.badgeText ?? ''),
            onChanged: notifier.setBadgeText,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!state.hasImage) ...[
            DropdownButton<PresetBackground>(
              value: state.presetBackground,
              hint: const Text('Preset background'),
              isExpanded: true,
              onChanged: notifier.setPresetBackground,
              items: PresetBackground.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Gradient'),
                  selected: state.backgroundType == BackgroundType.gradient,
                  onSelected: (_) =>
                      notifier.setBackgroundType(BackgroundType.gradient),
                ),
                ChoiceChip(
                  label: const Text('Preset'),
                  selected: state.backgroundType == BackgroundType.preset,
                  onSelected: (_) =>
                      notifier.setBackgroundType(BackgroundType.preset),
                ),
              ],
            ),
          ],
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
              child: GestureDetector(
                onDoubleTap: () {
                  Haptics.selectionClick();
                  notifier.setHeadlineScale(1.0);
                },
                child: Slider(
                  value: state.headlineScale,
                  min: 0.85,
                  max: 1.15,
                  divisions: 6,
                  label: '${(state.headlineScale * 100).round()}%',
                  onChanged: notifier.setHeadlineScale,
                  onChangeEnd: (_) => Haptics.selectionClick(),
                ),
              ),
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
    final fields = CardFieldRegistry.fieldsFor(state.selectedTemplate);
    final editableFields = fields
        .where(
          (f) => f.type != CardFieldType.list && f.type != CardFieldType.bool_,
        )
        .toList();
    final groups = ['primary', 'secondary', 'optional'];

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
              state.isExtracting ? 'Regenerating...' : 'AI Rewrite All',
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
        for (final group in groups) ...[
          if (editableFields.any((f) => f.group == group)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Row(
                children: [
                  Text(
                    group.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            ...editableFields.where((f) => f.group == group).map((field) {
              final rawVal = json[field.key];
              final initialVal = rawVal == null ? '' : rawVal.toString();
              final isMissing = state.missingFields.contains(field.key);

              return _DynamicField(
                key: ValueKey('${state.cardData!.runtimeType}_${field.key}'),
                fieldKey: field.key,
                label: field.label,
                maxLen: field.maxChars > 0 ? field.maxChars : 120,
                isRequired: field.required,
                isMissing: isMissing,
                aiHint: field.aiHint,
                initialValue: initialVal,
                onChanged: (v) => notifier.updateCardField(field.key, v),
                isRewriting: state.isRewriting(field.key),
                onRewrite: () async {
                  final brief = state.brief;
                  if (brief == null) return;
                  final prefs = getIt<PreferencesService>();
                  final apiKey = await prefs.getApiKey(brief.provider);
                  if (apiKey == null || apiKey.isEmpty) return;
                  notifier.rewriteDynamicField(
                    fieldKey: field.key,
                    provider: brief.provider,
                    modelId: brief.modelId,
                    apiKey: apiKey,
                  );
                },
              );
            }),
          ],
        ],
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(
                    state.watermarkImage == null
                        ? 'Upload Logo'
                        : 'Change Logo',
                  ),
                  onPressed: () async {
                    final source = await _pickImageSource(context);
                    if (source != null) {
                      await notifier.pickWatermarkImage(source);
                    }
                  },
                ),
              ),
              if (state.watermarkImage != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Remove logo',
                  onPressed: notifier.removeWatermarkImage,
                ),
              ],
            ],
          ),
          if (state.watermarkImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusSm,
              child: Image.file(
                state.watermarkImage!,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Size', style: theme.textTheme.labelMedium),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    Haptics.selectionClick();
                    notifier.setWatermarkSize(64.0);
                  },
                  child: Slider(
                    value: state.watermarkSize,
                    min: 24,
                    max: 160,
                    divisions: 17,
                    label: '${state.watermarkSize.round()}',
                    onChanged: notifier.setWatermarkSize,
                    onChangeEnd: (_) => Haptics.selectionClick(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tip: drag watermark on card to reposition',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Future<ImageSource?> _pickImageSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
          ],
        ),
      ),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLen;
  final int maxLines;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRewrite;
  final bool isRewriting;
  final bool isMissing;
  final bool isRequired;
  final String? aiHint;

  const _Field({
    required this.controller,
    required this.label,
    required this.maxLen,
    required this.maxLines,
    required this.onChanged,
    this.onRewrite,
    this.isRewriting = false,
    this.isMissing = false,
    this.isRequired = false,
    this.aiHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarn = isMissing && isRequired;

    return TextField(
      controller: controller,
      maxLength: maxLen,
      maxLines: maxLines,
      minLines: 1,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: isWarn
              ? Colors.amber.shade700
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: isWarn ? FontWeight.w700 : FontWeight.w500,
        ),
        helperText: isWarn ? 'Missing value — tap to fill' : aiHint,
        helperStyle: isWarn
            ? TextStyle(
                color: Colors.amber.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )
            : null,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(
            color: isWarn ? Colors.amber.shade600 : theme.colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(
            color: isWarn
                ? Colors.amber.shade600
                : theme.colorScheme.outline.withValues(alpha: 0.7),
            width: isWarn ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(
            color: isWarn ? Colors.amber.shade600 : theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isWarn
            ? Colors.amber.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
  final String label;
  final int maxLen;
  final bool isRequired;
  final bool isMissing;
  final String? aiHint;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onRewrite;
  final bool isRewriting;

  const _DynamicField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.maxLen,
    required this.isRequired,
    required this.isMissing,
    this.aiHint,
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
      text: (widget.initialValue == 'N/A' || widget.initialValue == '-')
          ? ''
          : widget.initialValue,
    );
  }

  @override
  void didUpdateWidget(_DynamicField old) {
    super.didUpdateWidget(old);
    final newVal = (widget.initialValue == 'N/A' || widget.initialValue == '-')
        ? ''
        : widget.initialValue;
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _Field(
        controller: _ctrl,
        label: widget.label,
        maxLen: widget.maxLen,
        maxLines: widget.maxLen > 60 ? 3 : 1,
        isRequired: widget.isRequired,
        isMissing: widget.isMissing,
        aiHint: widget.aiHint,
        onChanged: widget.onChanged,
        isRewriting: widget.isRewriting,
        onRewrite: widget.onRewrite,
      ),
    );
  }
}
