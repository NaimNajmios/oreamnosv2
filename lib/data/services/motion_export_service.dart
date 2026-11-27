import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';

/// Encodes captured card frames as an animated GIF for Stories/Reels.
///
/// No FFmpegKit dependency: frames come from `RepaintBoundary.toImage` and are
/// assembled here with the pure-Dart `image` package.
@lazySingleton
class MotionExportService {
  List<int> encodeGif(List<List<int>> pngFrames, {int delayMs = 100}) {
    if (pngFrames.isEmpty) {
      throw ArgumentError.value(
        pngFrames,
        'pngFrames',
        'At least one frame is required',
      );
    }

    final encoder = img.GifEncoder();
    img.Image? first;
    for (final bytes in pngFrames) {
      final frame = img.decodeImage(Uint8List.fromList(bytes));
      if (frame == null) {
        throw const FormatException('Could not decode a captured frame');
      }
      first ??= frame;
      // GifEncoder durations are in 1/100 second units.
      encoder.addFrame(frame, duration: (delayMs / 10).round().clamp(1, 65535));
    }
    return encoder.encode(first!);
  }
}
