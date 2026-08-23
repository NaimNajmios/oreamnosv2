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

    // Ball mark
    final Paint markPaint = Paint()..color = const Color(0xFFF4F1EB);
    final Path path = Path()
      ..moveTo(256, 138)
      ..lineTo(324.5, 187.8)
      ..lineTo(298.3, 268.2)
      ..lineTo(213.7, 268.2)
      ..lineTo(187.5, 187.8)
      ..close();
    canvas.drawPath(path, markPaint);

    // Text lines
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(168, 320, 176, 16), const Radius.circular(8)),
      markPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(196, 352, 120, 16), const Radius.circular(8)),
      markPaint,
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
