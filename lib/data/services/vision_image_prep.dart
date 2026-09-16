import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Downscales image bytes before sending to cloud vision.
///
/// Image tokens scale with pixels; capping at 1024px cuts tokens ~60-75%
/// and keeps payloads under Groq TPM caps and mobile-network friendly.
abstract final class VisionImagePrep {
  static const int defaultMaxDim = 1024;

  static Future<Uint8List> downscaleForVision(
    Uint8List bytes, {
    int maxDim = defaultMaxDim,
  }) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final w = image.width;
      final h = image.height;
      final longest = w > h ? w : h;
      if (longest <= maxDim) return bytes;
      final scale = maxDim / longest;
      final targetW = (w * scale).round().clamp(1, maxDim);
      final targetH = (h * scale).round().clamp(1, maxDim);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      final picture = recorder.endRecording();
      final out = await picture.toImage(targetW, targetH);
      try {
        final data = await out.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) return bytes;
        return data.buffer.asUint8List();
      } finally {
        out.dispose();
        picture.dispose();
      }
    } finally {
      image.dispose();
      codec.dispose();
    }
  }

  static String toBase64(Uint8List bytes) => base64Encode(bytes);

  static String dataUrl(Uint8List bytes, {String mimeType = 'image/png'}) =>
      'data:$mimeType;base64,${toBase64(bytes)}';

  static String detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/jpeg';
    }
    return 'image/png';
  }
}
