import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

/// Interactive canvas text element that supports:
/// - Single-tap to highlight and switch bottom dock to edit mode.
/// - Double-tap to edit text directly inline on the canvas.
class EditableCanvasText extends ConsumerStatefulWidget {
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
  ConsumerState<EditableCanvasText> createState() => _EditableCanvasTextState();
}

class _EditableCanvasTextState extends ConsumerState<EditableCanvasText> {
  bool _isEditingInline = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(EditableCanvasText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingInline && widget.text != oldWidget.text) {
      _controller.text = widget.text;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditingInline) {
      _commitEdit();
    }
  }

  void _commitEdit() {
    if (_controller.text != widget.text) {
      ref
          .read(cardGeneratorViewModelProvider.notifier)
          .updateCardField(widget.fieldKey, _controller.text);
    }
    setState(() {
      _isEditingInline = false;
    });
  }

  void _startInlineEdit() {
    Haptics.lightImpact();
    setState(() {
      _isEditingInline = true;
      _controller.text = widget.text;
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = ref.watch(
      cardGeneratorViewModelProvider.select(
        (s) => s.focusedField == widget.fieldKey,
      ),
    );

    final effectiveShadows = widget.enableGlow
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
            ...?widget.style?.shadows,
          ]
        : widget.style?.shadows;

    final effectiveStyle = widget.style != null
        ? widget.style!.copyWith(shadows: effectiveShadows)
        : (widget.enableGlow ? TextStyle(shadows: effectiveShadows) : null);

    if (_isEditingInline) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          border: Border.all(color: Colors.amberAccent, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: effectiveStyle ?? const TextStyle(color: Colors.white),
                textAlign: widget.textAlign ?? TextAlign.start,
                maxLines: widget.maxLines ?? 3,
                minLines: 1,
                cursorColor: Colors.amberAccent,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _commitEdit(),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Colors.amberAccent,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: _commitEdit,
            ),
          ],
        ),
      );
    }

    Widget textWidget = widget.autoSize
        ? AutoSizeText(
            widget.text,
            style: effectiveStyle,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            minFontSize: widget.minFontSize,
            stepGranularity: widget.stepGranularity,
            overflow: TextOverflow.ellipsis,
          )
        : Text(
            widget.text,
            style: effectiveStyle,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.selectionClick();
        ref
            .read(cardGeneratorViewModelProvider.notifier)
            .setActivePanel('text');
        ref
            .read(cardGeneratorViewModelProvider.notifier)
            .setFocusedField(widget.fieldKey);
      },
      onDoubleTap: _startInlineEdit,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused
                ? Colors.blue.withValues(alpha: 0.7)
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
