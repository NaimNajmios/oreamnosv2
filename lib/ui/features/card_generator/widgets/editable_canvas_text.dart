import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

class EditableCanvasText extends ConsumerWidget {
  final String text;
  final String fieldKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final double minFontSize;
  final double stepGranularity;
  final bool autoSize;
  final bool enableGlow;

  const EditableCanvasText(
    this.text, {
    super.key,
    required this.fieldKey,
    this.style,
    this.textAlign,
    this.maxLines,
    this.minFontSize = 8,
    this.stepGranularity = 1,
    this.autoSize = true,
    this.enableGlow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFocused =
        ref.watch(cardGeneratorViewModelProvider).focusedField == fieldKey;

    final effectiveShadows = enableGlow
        ? [
            const Shadow(
              color: Color(0xB3000000),
              blurRadius: 28,
              offset: Offset(0, 6),
            ),
            const Shadow(
              color: Color(0x66000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
            ...?style?.shadows,
          ]
        : style?.shadows;

    final effectiveStyle = style != null
        ? style!.copyWith(shadows: effectiveShadows)
        : (enableGlow ? TextStyle(shadows: effectiveShadows) : null);

    Widget textWidget = autoSize
        ? AutoSizeText(
            text,
            style: effectiveStyle,
            textAlign: textAlign,
            maxLines: maxLines,
            minFontSize: minFontSize,
            stepGranularity: stepGranularity,
            overflow: TextOverflow.ellipsis,
          )
        : Text(
            text,
            style: effectiveStyle,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref
            .read(cardGeneratorViewModelProvider.notifier)
            .setActivePanel('text');
        ref
            .read(cardGeneratorViewModelProvider.notifier)
            .setFocusedField(fieldKey);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused
                ? Colors.blue.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: isFocused ? const EdgeInsets.all(2) : EdgeInsets.zero,
        margin: isFocused ? const EdgeInsets.all(-4) : EdgeInsets.zero,
        child: textWidget,
      ),
    );
  }
}
