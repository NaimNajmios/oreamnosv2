import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';

import '../../view_models/card_generator_view_model.dart';

class TypographyPanel extends ConsumerWidget {
  const TypographyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedFont = ref.watch(
      cardGeneratorViewModelProvider.select((s) => s.selectedFont),
    );
    final headlineScale = ref.watch(
      cardGeneratorViewModelProvider.select((s) => s.headlineScale),
    );
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    final scalePercent = (headlineScale * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(
              label: 'Inter',
              selected: selectedFont == AppFont.defaultFont,
              onTap: () => notifier.setFont(AppFont.defaultFont),
            ),
            AppChip(
              label: 'Lora Serif',
              selected: selectedFont == AppFont.classicSerif,
              onTap: () => notifier.setFont(AppFont.classicSerif),
            ),
            AppChip(
              label: 'Space Mono',
              selected: selectedFont == AppFont.typewriter,
              onTap: () => notifier.setFont(AppFont.typewriter),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('Size', style: theme.textTheme.labelMedium),
            Expanded(
              child: Semantics(
                slider: true,
                label: 'Headline Size',
                value: '$scalePercent%',
                onIncrease: () {
                  final next = (headlineScale + 0.05).clamp(0.85, 1.15);
                  notifier.setHeadlineScale(next);
                },
                onDecrease: () {
                  final next = (headlineScale - 0.05).clamp(0.85, 1.15);
                  notifier.setHeadlineScale(next);
                },
                child: GestureDetector(
                  onDoubleTap: () {
                    Haptics.selectionClick();
                    notifier.setHeadlineScale(1.0);
                  },
                  child: Slider(
                    value: headlineScale,
                    min: 0.85,
                    max: 1.15,
                    divisions: 6,
                    label: '$scalePercent%',
                    onChanged: notifier.setHeadlineScale,
                    onChangeEnd: (_) => Haptics.selectionClick(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
