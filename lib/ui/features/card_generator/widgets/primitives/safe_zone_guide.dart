import 'package:flutter/material.dart';

import '../../../../../domain/models/card_config.dart';

/// Editor-only overlay showing the platform safe area for an export ratio.
/// It is drawn outside the export boundary so it never appears in captures.
class SafeZoneGuide extends StatelessWidget {
  const SafeZoneGuide({super.key, required this.size});

  final ExportSize size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SafeZonePainter(size: size),
        size: Size.infinite,
      ),
    );
  }
}

class _SafeZonePainter extends CustomPainter {
  const _SafeZonePainter({required this.size});

  final ExportSize size;

  @override
  void paint(Canvas canvas, Size area) {
    final top = size == ExportSize.story ? 0.14 : 0.06;
    final bottom = size == ExportSize.story ? 0.35 : 0.06;
    final sides = 0.06;

    final rect = Rect.fromLTRB(
      area.width * sides,
      area.height * top,
      area.width * (1 - sides),
      area.height * (1 - bottom),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SafeZonePainter old) => old.size != size;
}
