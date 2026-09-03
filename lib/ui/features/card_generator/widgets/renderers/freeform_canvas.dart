import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/data/services/gradient_builder.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

import '../draggable_canvas_element.dart';
import '../editable_canvas_text.dart';

class FreeformCanvas extends ConsumerWidget {
  const FreeformCanvas({super.key, required this.data, required this.config});
  final CardData data;
  final CardConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);
    final colors = config.colorPair;

    final headline = data.headline;
    final subtext = data.subtext;
    final microStat = data.microStat ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: config.backgroundImagePath != null
            ? null
            : GradientBuilder.vertical(colors),
      ),
      child: Stack(
        children: [
          if (config.showScrim)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: GradientBuilder.scrimFor(
                    config.scrimType,
                    config.overlayOpacity,
                  ),
                ),
              ),
            ),

          if (headline.isNotEmpty)
            DraggableCanvasElement(
              offset: state.headlineOffset,
              onDragStart: notifier.saveDragSnapshot,
              onOffsetChanged: (o) =>
                  notifier.updateElementOffset('headline', o),
              child: EditableCanvasText(
                headline,
                fieldKey: 'headline',
                autoSize: false,
                style: config.font(fontSize: 32, fontWeight: FontWeight.w900),
              ),
            ),

          if (subtext.isNotEmpty)
            DraggableCanvasElement(
              offset: state.subtextOffset,
              onDragStart: notifier.saveDragSnapshot,
              onOffsetChanged: (o) =>
                  notifier.updateElementOffset('subtext', o),
              child: EditableCanvasText(
                subtext,
                fieldKey: 'subtext',
                autoSize: false,
                style: config.font(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (microStat.isNotEmpty)
            DraggableCanvasElement(
              offset: state.microStatOffset,
              onDragStart: notifier.saveDragSnapshot,
              onOffsetChanged: (o) =>
                  notifier.updateElementOffset('microStat', o),
              child: EditableCanvasText(
                microStat,
                fieldKey: 'microStat',
                autoSize: false,
                style: config.font(color: Colors.white54, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
