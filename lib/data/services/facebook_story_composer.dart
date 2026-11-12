import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';

import '../../ui/features/facebook/widgets/facebook_story_painter.dart';

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

    final source = await _loadImage(sourceImagePath);
    FacebookStoryPainter(title: title, background: source).paint(canvas, size);
    source?.dispose();

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
