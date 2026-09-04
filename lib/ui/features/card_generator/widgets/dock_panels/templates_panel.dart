import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

import '../../view_models/card_generator_view_model.dart';
import '../template_picker_grid.dart';

class TemplatesPanel extends ConsumerWidget {
  const TemplatesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTemplate = ref.watch(
      cardGeneratorViewModelProvider.select((s) => s.selectedTemplate),
    );
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TemplatePickerGrid(
          selected: selectedTemplate,
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
}
