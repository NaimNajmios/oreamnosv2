import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rasterises a painter at [size] for golden comparison.
Future<ui.Image> renderPainter(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  picture.dispose();
  return image;
}

/// Compares [image] against the PNG at [path], writing the golden first time.
///
/// Anti-aliasing and platform font rasterisation differ slightly between
/// machines, so the comparison tolerates a small per-pixel difference rather
/// than demanding bit-equality.
Future<void> expectGolden(
  ui.Image image,
  String path, {
  double tolerance = 0.02,
}) async {
  final file = File(path);
  final bytes = await _rgba(image);
  if (!file.existsSync()) {
    await file.parent.create(recursive: true);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(png, isNotNull, reason: 'Could not encode golden $path');
    await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    return;
  }

  final goldenImage = await _decodePng(await file.readAsBytes());
  expect(
    goldenImage.width,
    image.width,
    reason: 'Golden width changed for $path',
  );
  expect(
    goldenImage.height,
    image.height,
    reason: 'Golden height changed for $path',
  );
  final goldenBytes = await _rgba(goldenImage);
  goldenImage.dispose();

  var differing = 0;
  var total = 0;
  for (var i = 0; i < bytes.length; i += 4) {
    total++;
    final dr = (bytes[i] - goldenBytes[i]).abs();
    final dg = (bytes[i + 1] - goldenBytes[i + 1]).abs();
    final db = (bytes[i + 2] - goldenBytes[i + 2]).abs();
    if (dr > 24 || dg > 24 || db > 24) differing++;
  }
  final ratio = total == 0 ? 0.0 : differing / total;
  expect(
    ratio,
    lessThanOrEqualTo(tolerance),
    reason:
        'Golden mismatch for $path: '
        '${(ratio * 100).toStringAsFixed(2)}% pixels differ',
  );
}

Future<ui.Image> _decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Uint8List> _rgba(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
