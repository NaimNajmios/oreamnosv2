import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';

import '../../view_models/card_generator_view_model.dart';
import '../background_picker.dart';

class BackgroundPanel extends ConsumerStatefulWidget {
  const BackgroundPanel({super.key});

  @override
  ConsumerState<BackgroundPanel> createState() => _BackgroundPanelState();
}

class _BackgroundPanelState extends ConsumerState<BackgroundPanel> {
  late TextEditingController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    final badge = ref.read(
      cardGeneratorViewModelProvider.select((s) => s.badgeText),
    );
    _badgeCtrl = TextEditingController(text: badge ?? '');
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    // Keep badge controller in sync if modified outside
    if (_badgeCtrl.text != (state.badgeText ?? '') &&
        !FocusScope.of(context).hasFocus) {
      _badgeCtrl.text = state.badgeText ?? '';
    }

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
                child: Semantics(
                  slider: true,
                  label: 'Image Opacity',
                  value: '${(state.imageOpacity * 100).round()}%',
                  onIncrease: () {
                    final next = (state.imageOpacity + 0.1).clamp(0.2, 1.0);
                    notifier.setImageOpacity(next);
                  },
                  onDecrease: () {
                    final next = (state.imageOpacity - 0.1).clamp(0.2, 1.0);
                    notifier.setImageOpacity(next);
                  },
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
              ),
            ],
          ),
          Row(
            children: [
              Text('Blur', style: theme.textTheme.labelSmall),
              Expanded(
                child: Semantics(
                  slider: true,
                  label: 'Background Blur',
                  value: '${state.backgroundBlurRadius.round()}',
                  onIncrease: () {
                    final next = (state.backgroundBlurRadius + 5.0).clamp(
                      0.0,
                      25.0,
                    );
                    notifier.setBackgroundBlurRadius(next);
                  },
                  onDecrease: () {
                    final next = (state.backgroundBlurRadius - 5.0).clamp(
                      0.0,
                      25.0,
                    );
                    notifier.setBackgroundBlurRadius(next);
                  },
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
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: 'Badge Text',
              hintText: 'e.g. LIVE, NEW',
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              isDense: true,
            ),
            controller: _badgeCtrl,
            onChanged: notifier.setBadgeText,
          ),
          const SizedBox(height: AppSpacing.sm),
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
    );
  }
}
