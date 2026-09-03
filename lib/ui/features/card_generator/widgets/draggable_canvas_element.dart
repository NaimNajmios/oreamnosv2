import 'package:flutter/material.dart';

/// Full-area drag wrapper that positions [child] by fractional [offset]
/// (0.05–0.95, centered via FractionalTranslation).
///
/// Extracted from `FreeformCanvas._DraggableElement` so any canvas can opt
/// into element dragging. Structured (flow-layout) canvases intentionally do
/// NOT use it — their Column flow would fight absolute positioning; drag
/// there is covered by the freeform template + watermark overlay.
class DraggableCanvasElement extends StatelessWidget {
  final Offset offset;
  final ValueChanged<Offset> onOffsetChanged;
  final VoidCallback? onDragStart;
  final Widget child;

  const DraggableCanvasElement({
    super.key,
    required this.offset,
    required this.onOffsetChanged,
    this.onDragStart,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final x = offset.dx * constraints.maxWidth;
          final y = offset.dy * constraints.maxHeight;

          return Stack(
            children: [
              Positioned(
                left: x,
                top: y,
                child: GestureDetector(
                  onPanStart: (_) => onDragStart?.call(),
                  onPanUpdate: (details) {
                    final newX = (x + details.delta.dx) / constraints.maxWidth;
                    final newY = (y + details.delta.dy) / constraints.maxHeight;
                    onOffsetChanged(Offset(newX, newY));
                  },
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
