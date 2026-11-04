import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oreamnos/data/services/facebook_image_cropper.dart';

void main() {
  group('FacebookImageCropper.cropRectFor', () {
    test('wide source is trimmed left and right', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 1000,
        height: 500,
        targetAspect: 1.0,
      );
      expect(rect.width, 500);
      expect(rect.height, 500);
      expect(rect.left, 250);
      expect(rect.top, 0);
    });

    test('tall source is trimmed top and bottom', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 500,
        height: 1000,
        targetAspect: 0.8,
      );
      expect(rect.width, 500);
      expect(rect.height, 625);
      expect(rect.top, 187.5);
      expect(rect.left, 0);
    });

    test('square source keeps its own size for 1:1', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 300,
        height: 300,
        targetAspect: 1.0,
      );
      expect(rect, const Rect.fromLTWH(0, 0, 300, 300));
    });

    test('feed aspect 1.91 centers a 4:5 card', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 1080,
        height: 1350,
        targetAspect: 1.91,
      );
      expect(rect.width, closeTo(1080, 0.01));
      expect(rect.height, closeTo(1080 / 1.91, 0.01));
      expect(rect.center.dy, closeTo(675, 0.01));
    });

    test('invalid dimensions return the full rect instead of throwing', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 0,
        height: 0,
        targetAspect: 1,
      );
      expect(rect, Rect.zero);
    });

    test('zoom shrinks the crop and keeps it centered', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 1000,
        height: 1000,
        targetAspect: 1.0,
        zoom: 2,
      );
      expect(rect.width, 500);
      expect(rect.height, 500);
      expect(rect.center, const Offset(500, 500));
    });

    test('positive offset pans toward the right/bottom edge', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 1000,
        height: 1000,
        targetAspect: 1.0,
        zoom: 2,
        offset: const Offset(1, 1),
      );
      expect(rect.left, 500);
      expect(rect.top, 500);
      expect(rect.right, 1000);
      expect(rect.bottom, 1000);
    });

    test('offset at zoom 1 is a no-op and cannot leave the source', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 1000,
        height: 500,
        targetAspect: 1.0,
        offset: const Offset(1, 1),
      );
      expect(rect, const Rect.fromLTWH(250, 0, 500, 500));
    });

    test('extreme zoom values clamp to the supported range', () {
      final rect = FacebookImageCropper.cropRectFor(
        width: 1000,
        height: 1000,
        targetAspect: 1.0,
        zoom: 99,
      );
      expect(rect.width, closeTo(250, 0.001));
      expect(rect.center, const Offset(500, 500));
    });
  });

  group('FacebookImageCropper.cropToFile', () {
    test('no-op crop returns the original file untouched', () async {
      final dir = await Directory.systemTemp.createTemp('oreamnos_crop');
      final source = File('${dir.path}/square.png');
      final image = img.Image(width: 100, height: 100);
      await source.writeAsBytes(img.encodePng(image));
      FacebookImageCropper.clearCache();

      final result = await FacebookImageCropper.cropToFile(
        sourcePath: source.path,
        targetAspect: 1.0,
        outputDir: dir.path,
      );
      expect(result, source.path);
      await dir.delete(recursive: true);
    });

    test('crop output is cached and reused', () async {
      final dir = await Directory.systemTemp.createTemp('oreamnos_crop');
      final source = File('${dir.path}/wide.png');
      final image = img.Image(width: 200, height: 100);
      await source.writeAsBytes(img.encodePng(image));
      FacebookImageCropper.clearCache();

      final first = await FacebookImageCropper.cropToFile(
        sourcePath: source.path,
        targetAspect: 1.0,
        outputDir: dir.path,
      );
      final second = await FacebookImageCropper.cropToFile(
        sourcePath: source.path,
        targetAspect: 1.0,
        outputDir: dir.path,
      );
      expect(first, isNotNull);
      expect(second, first);
      await dir.delete(recursive: true);
    });
  });
}
