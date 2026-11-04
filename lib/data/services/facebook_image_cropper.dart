import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Offset, Rect;
import 'package:image/image.dart' as img;

/// Crop helper for the Facebook composer.
///
/// The preview renders the attached photo inside `AspectRatio(aspect.ratio)`
/// with the same zoom/offset; this service bakes that frame into the uploaded
/// file so Facebook cannot re-crop the card unpredictably.
///
/// Encoding uses the pure-Dart `image` package (JPEG q85, EXIF stripped,
/// ≤2048 px) on a background isolate. If that fails, it falls back to a
/// `dart:ui` PNG crop.
abstract final class FacebookImageCropper {
  /// Longest output edge. Facebook recompresses anything larger, and 2048 is
  /// the same ceiling used by the gallery picker.
  static const int maxOutputEdge = 2048;

  static const int jpegQuality = 85;

  /// Source rectangle (in image pixels) for a centered `targetAspect`
  /// (width / height) crop, then zoomed and panned within that frame.
  ///
  /// At `zoom == 1` panning is disabled (the frame exactly fills the image).
  /// `offset` is normalized -1..1 and clamped so the rect stays in bounds.
  static Rect cropRectFor({
    required int width,
    required int height,
    required double targetAspect,
    double zoom = 1.0,
    Offset offset = Offset.zero,
  }) {
    if (width <= 0 || height <= 0 || targetAspect <= 0) {
      return Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    }
    final imageAspect = width / height;
    final double baseWidth;
    final double baseHeight;
    if (imageAspect > targetAspect) {
      // Source is wider: keep full height, trim left/right.
      baseWidth = height * targetAspect;
      baseHeight = height.toDouble();
    } else {
      // Source is taller: keep full width, trim top/bottom.
      baseWidth = width.toDouble();
      baseHeight = width / targetAspect;
    }
    final base = Rect.fromLTWH(
      (width - baseWidth) / 2,
      (height - baseHeight) / 2,
      baseWidth,
      baseHeight,
    );

    final safeZoom = zoom.clamp(1.0, 4.0);
    final cropWidth = baseWidth / safeZoom;
    final cropHeight = baseHeight / safeZoom;
    final maxDx = (baseWidth - cropWidth) / 2;
    final maxDy = (baseHeight - cropHeight) / 2;
    final dx = offset.dx.clamp(-1.0, 1.0).toDouble() * maxDx;
    final dy = offset.dy.clamp(-1.0, 1.0).toDouble() * maxDy;

    final left = (base.left + maxDx + dx)
        .clamp(0.0, math.max(0.0, width - cropWidth))
        .toDouble();
    final top = (base.top + maxDy + dy)
        .clamp(0.0, math.max(0.0, height - cropHeight))
        .toDouble();
    return Rect.fromLTWH(left, top, cropWidth, cropHeight);
  }

  /// Small in-memory cache of recent crop outputs. Keyed by source + crop
  /// parameters, so repeated publishes reuse the encoded file.
  static final Map<String, String> _cropCache = <String, String>{};
  static const int _maxCachedCrops = 20;

  static void clearCache() => _cropCache.clear();

  /// Decodes [sourcePath], applies the crop, and writes a JPEG into
  /// [outputDir]. Returns the new path, or null when the source can't be
  /// decoded/encoded (caller falls back to the original file).
  static Future<String?> cropToFile({
    required String sourcePath,
    required double targetAspect,
    required String outputDir,
    double zoom = 1.0,
    Offset offset = Offset.zero,
    int quality = jpegQuality,
  }) async {
    final cacheKey =
        '$sourcePath|$targetAspect|$zoom|${offset.dx}|${offset.dy}|$quality';
    final cached = _cropCache[cacheKey];
    if (cached != null && File(cached).existsSync()) return cached;
    try {
      final result = await Isolate.run(
        () => _encodeJpegCrop({
          'sourcePath': sourcePath,
          'targetAspect': targetAspect,
          'outputDir': outputDir,
          'zoom': zoom,
          'offsetX': offset.dx,
          'offsetY': offset.dy,
          'quality': quality,
        }),
      );
      if (result != null) {
        _remember(cacheKey, result);
        return result;
      }
    } catch (_) {
      // Fall through to the dart:ui PNG path.
    }
    final fallback = await _cropWithUi(
      sourcePath: sourcePath,
      targetAspect: targetAspect,
      outputDir: outputDir,
      zoom: zoom,
      offset: offset,
    );
    if (fallback != null) _remember(cacheKey, fallback);
    return fallback;
  }

  static void _remember(String key, String path) {
    if (_cropCache.length >= _maxCachedCrops) {
      _cropCache.remove(_cropCache.keys.first);
    }
    _cropCache[key] = path;
  }

  /// Top-level isolate entry point (must not capture non-sendable state).
  static String? _encodeJpegCrop(Map<String, Object> job) {
    uiImageFallback: // ignore: unused_label
    try {
      final sourcePath = job['sourcePath'] as String;
      final outputDir = job['outputDir'] as String;
      final targetAspect = (job['targetAspect'] as num).toDouble();
      final zoom = (job['zoom'] as num?)?.toDouble() ?? 1.0;
      final offset = Offset(
        (job['offsetX'] as num?)?.toDouble() ?? 0,
        (job['offsetY'] as num?)?.toDouble() ?? 0,
      );
      final quality = (job['quality'] as num?)?.toInt() ?? jpegQuality;

      final bytes = File(sourcePath).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final oriented = img.bakeOrientation(decoded);
      final sourceAspect = oriented.width / oriented.height;
      final aspectDiff = (sourceAspect - targetAspect).abs() / targetAspect;
      if (zoom == 1.0 && offset == Offset.zero && aspectDiff <= 0.005) {
        return sourcePath;
      }
      final rect = cropRectFor(
        width: oriented.width,
        height: oriented.height,
        targetAspect: targetAspect,
        zoom: zoom,
        offset: offset,
      );
      if (rect.width < 1 || rect.height < 1) return null;

      final x = rect.left.round().clamp(0, oriented.width - 1);
      final y = rect.top.round().clamp(0, oriented.height - 1);
      final w = rect.width.round().clamp(1, oriented.width - x);
      final h = rect.height.round().clamp(1, oriented.height - y);
      var cropped = img.copyCrop(oriented, x: x, y: y, width: w, height: h);
      if (cropped.width > maxOutputEdge) {
        cropped = img.copyResize(
          cropped,
          width: maxOutputEdge,
          interpolation: img.Interpolation.average,
        );
      }
      final encoded = img.encodeJpg(cropped, quality: quality);
      if (encoded.isEmpty) return null;

      final file = File(
        '$outputDir/oreamnos_fb_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      file.writeAsBytesSync(encoded);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Dependency-free fallback (PNG). Kept for environments where the pure
  /// Dart decoder fails on an exotic source.
  static Future<String?> _cropWithUi({
    required String sourcePath,
    required double targetAspect,
    required String outputDir,
    required double zoom,
    required Offset offset,
  }) async {
    ui.Image? image;
    ui.Image? output;
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;

      final src = cropRectFor(
        width: image.width,
        height: image.height,
        targetAspect: targetAspect,
        zoom: zoom,
        offset: offset,
      );
      if (src.width < 1 || src.height < 1) return null;

      final scale = math.min(1.0, maxOutputEdge / src.width);
      final outWidth = math.max(1, (src.width * scale).round());
      final outHeight = math.max(1, (src.height * scale).round());

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        image,
        src,
        Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      output = await picture.toImage(outWidth, outHeight);
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;

      final file = File(
        '$outputDir/oreamnos_fb_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List());
      return file.path;
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      output?.dispose();
    }
  }
}
