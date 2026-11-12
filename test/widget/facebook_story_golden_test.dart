import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_story_painter.dart';

import '../helpers/golden_helpers.dart';

const Size _canvas = Size(270, 480);

Future<ui.Image> _sourceImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 200, 200),
    Paint()..color = const Color(0xFFE53935),
  );
  canvas.drawRect(
    const Rect.fromLTWH(200, 0, 200, 200),
    Paint()..color = const Color(0xFF1E88E5),
  );
  canvas.drawCircle(
    const Offset(200, 100),
    60,
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 200);
  picture.dispose();
  return image;
}

void main() {
  testWidgets('Story card with title', (tester) async {
    await tester.runAsync(() async {
      final image = await renderPainter(
        const FacebookStoryPainter(title: 'Oreamnos Story Title'),
        _canvas,
      );
      await expectGolden(image, 'test/goldens/facebook_story_title.png');
      image.dispose();
    });
  });

  testWidgets('Story card keeps a clean background without a title', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final image = await renderPainter(
        const FacebookStoryPainter(title: '   '),
        _canvas,
      );
      await expectGolden(image, 'test/goldens/facebook_story_empty_title.png');
      image.dispose();
    });
  });

  testWidgets('Story card crops a source image to 9:16', (tester) async {
    await tester.runAsync(() async {
      final source = await _sourceImage();
      final image = await renderPainter(
        FacebookStoryPainter(title: 'Cropped', background: source),
        _canvas,
      );
      await expectGolden(image, 'test/goldens/facebook_story_crop.png');
      image.dispose();
      source.dispose();
    });
  });
}
