import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';

import 'facebook_image_cropper.dart';

/// Renders a 1080×1920 (9:16) Story image with the short title baked in.
/// The Page Stories API has no caption field, so the title is part of the
/// pixels; the full caption stays on the feed post.
@lazySingleton
class FacebookStoryComposer {
  static const int outputWidth = 1080;
  static const int outputHeight = 1920;

  Future<String> compose({
    String? sourceImagePath,
    required String title,
    required String outputDir,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1080, 1920);
    final rect = Offset.zero & size;

    final source = await _loadImage(sourceImagePath);
    if (source != null) {
      final src = FacebookImageCropper.cropRectFor(
        width: source.width,
        height: source.height,
        targetAspect: outputWidth / outputHeight,
      );
      canvas.drawImageRect(
        source,
        src,
        rect,
        Paint()..filterQuality = FilterQuality.high,
      );
      source.dispose();
    } else {
      _paintGeneratedBackground(canvas, size);
    }

    // Legibility scrim behind the title.
    final scrim = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.45),
        Offset(0, size.height),
        [const Color(0x00000000), const Color(0xB3000000)],
      );
    canvas.drawRect(rect, scrim);

    _paintTitle(canvas, title, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (data == null) {
      throw StateError('Could not render the Story image.');
    }
    final jpg = await Isolate.run(
      () => _encodeJpg(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
    );
    final file = File(
      '$outputDir/oreamnos_story_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(jpg, flush: true);
    return file.path;
  }

  static void _paintGeneratedBackground(Canvas canvas, Size size) {
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

  static void _paintTitle(Canvas canvas, String title, Size size) {
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

  static Future<ui.Image?> _loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: outputWidth,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Uint8List _encodeJpg(Uint8List png) {
    final decoded = img.decodeImage(png);
    if (decoded == null) return png;
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
  }
}
