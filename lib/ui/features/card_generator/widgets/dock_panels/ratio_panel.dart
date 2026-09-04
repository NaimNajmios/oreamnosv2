import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../view_models/card_generator_view_model.dart';
import '../ratio_selector.dart';

class RatioPanel extends ConsumerWidget {
  const RatioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRatio = ref.watch(
      cardGeneratorViewModelProvider.select((s) => s.selectedRatio),
    );
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    return Align(
      alignment: Alignment.center,
      child: RatioSelector(
        selected: selectedRatio,
        onSelect: notifier.setRatio,
      ),
    );
  }
}
