import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate icon PNG', () async {
    const double size = 1024.0;
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTRB(0, 0, size, size));

    final double scale = size / 512.0;
    canvas.scale(scale, scale);

    // Background
    final Paint bgPaint = Paint()..color = const Color(0xFF1C1C1C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 512, 512), const Radius.circular(115)),
      bgPaint,
    );

    // Ball mark — tri-tone flat palette (amber / teal / indigo) keeps #1C1C1C bg
    final Paint pentagonPaint = Paint()..color = const Color(0xFFF59E0B); // amber
    final Path path = Path()
      ..moveTo(256, 138)
      ..lineTo(324.5, 187.8)
      ..lineTo(298.3, 268.2)
      ..lineTo(213.7, 268.2)
      ..lineTo(187.5, 187.8)
      ..close();
    canvas.drawPath(path, pentagonPaint);

    // Text lines — teal + indigo
    final Paint tealPaint = Paint()..color = const Color(0xFF0EA5E9);
    final Paint indigoPaint = Paint()..color = const Color(0xFF4F46E5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(168, 320, 176, 16), const Radius.circular(8)),
      tealPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(196, 352, 120, 16), const Radius.circular(8)),
      indigoPaint,
    );

    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    
    if (byteData != null) {
      final File file = File('icon/icon.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      print('Saved icon to icon/icon.png');
    }
  });
}
