import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Captures a list of already-laid-out repaint boundaries into ordered PNG
/// frames, ready for [MotionExportService.encodeGif].
@lazySingleton
class MotionCaptureService {
  Future<List<List<int>>> captureFrames(
    List<GlobalKey> keys, {
    double pixelRatio = 2.0,
  }) async {
    final frames = <List<int>>[];
    for (final key in keys) {
      final boundary = key.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Motion frame key has no RenderRepaintBoundary');
      }
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) {
        throw StateError('Failed to encode a motion frame');
      }
      frames.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
    return frames;
  }
}
