import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:oreamnos/data/services/facebook_image_cropper.dart';

/// Paints a 9:16 Story card: optional cover crop, a legibility scrim, and the
/// short title. Extracted from `FacebookStoryComposer` so the exact layout can
/// be golden-tested without encoding a JPEG.
class FacebookStoryPainter extends CustomPainter {
  const FacebookStoryPainter({required this.title, this.background});

  static const int designWidth = 1080;
  static const int designHeight = 1920;

  final String title;
  final ui.Image? background;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / designWidth;
    final scaleY = size.height / designHeight;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    const designSize = Size(1080, 1920);
    final rect = Offset.zero & designSize;
    final source = background;
    if (source != null) {
      final src = FacebookImageCropper.cropRectFor(
        width: source.width,
        height: source.height,
        targetAspect: designWidth / designHeight,
      );
      canvas.drawImageRect(
        source,
        src,
        rect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      paintGeneratedBackground(canvas, designSize);
    }

    // Legibility scrim behind the title.
    final scrim = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, designSize.height * 0.45),
        Offset(0, designSize.height),
        [const Color(0x00000000), const Color(0xB3000000)],
      );
    canvas.drawRect(rect, scrim);

    paintTitle(canvas, title, designSize);
    canvas.restore();
  }

  static void paintGeneratedBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          const [Color(0xFF0B3D91), Color(0xFF6D28D9), Color(0xFF111827)],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.2),
      size.width * 0.42,
      Paint()..color = const Color(0x33FFFFFF),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.72),
      size.width * 0.3,
      Paint()..color = const Color(0x1AFFFFFF),
    );
  }

  static void paintTitle(Canvas canvas, String title, Size size) {
    final value = title.trim();
    if (value.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 76,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          shadows: [Shadow(color: Color(0x66000000), blurRadius: 18)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
      textAlign: TextAlign.left,
    )..layout(maxWidth: size.width - 160);
    final x = 80.0;
    final y = size.height - 120 - painter.height;
    painter.paint(canvas, Offset(x, y));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant FacebookStoryPainter oldDelegate) {
    return oldDelegate.title != title || oldDelegate.background != background;
  }
}
