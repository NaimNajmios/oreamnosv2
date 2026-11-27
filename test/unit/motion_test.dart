import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oreamnos/data/services/motion_export_service.dart';

void main() {
  group('MotionExportService', () {
    final service = MotionExportService();

    test('encodes captured frames as an animated GIF', () {
      final frames = <List<int>>[];
      for (var i = 0; i < 3; i++) {
        final image = img.Image(width: 40, height: 50);
        img.fill(image, color: img.ColorRgb8(255, 100 * i, 0));
        frames.add(img.encodePng(image));
      }

      final gif = service.encodeGif(frames, delayMs: 120);
      expect(gif.length, greaterThan(20));
      expect(String.fromCharCodes(gif.take(6)), 'GIF89a');
    });

    test('rejects an empty frame list', () {
      expect(() => service.encodeGif(const []), throwsArgumentError);
    });
  });
}
