import 'package:injectable/injectable.dart';

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:oreamnos/config/theme/card_scale.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

@lazySingleton
class ExportService {
  /// Captures the widget inside the RepaintBoundary with the given GlobalKey
  /// and returns it as a PNG byte array.
  Future<List<int>> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception(
        'Could not find RenderRepaintBoundary for the given key.',
      );
    }

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert image to byte data.');
    }

    return byteData.buffer.asUint8List();
  }

  /// Pixel ratio that makes the captured canvas exactly [size]'s pixel
  /// width, since the editor stage renders at [CardScale.designWidth].
  static double pixelRatio(ExportSize size) =>
      size.width / CardScale.designWidth;

  /// Captures the same boundary as [capturePng] but encodes JPEG at [quality].
  Future<List<int>> captureJpeg(
    GlobalKey boundaryKey, {
    required ExportSize size,
    int quality = 88,
  }) async {
    final png = await capturePng(boundaryKey, pixelRatio: pixelRatio(size));
    final decoded = img.decodeImage(Uint8List.fromList(png));
    if (decoded == null) {
      throw Exception('Failed to decode captured PNG for JPEG export.');
    }
    final encoded = img.encodeJpg(decoded, quality: quality.clamp(1, 100));
    return encoded;
  }

  /// Shares several ordered card images as one native share payload.
  Future<void> sharePages(
    List<List<int>> pages, {
    String filename = 'oreamnos_slide',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final files = <XFile>[];
    for (var i = 0; i < pages.length; i++) {
      final file = File('${tempDir.path}/${filename}_${i + 1}.png');
      await file.writeAsBytes(pages[i]);
      files.add(XFile(file.path));
    }
    await SharePlus.instance.share(ShareParams(files: files));
  }

  /// Saves the captured PNG bytes to the device's gallery (Oreamnos album).
  /// PNG is lossless — preferred over JPEG95 for flat graphics/text cards.
  /// Capture at pixelRatio 3.0 yields ~1080px+ output (Android exact-px parity).
  Future<bool> saveToGallery(
    List<int> pngBytes, {
    String filename = 'oreamnos_card.png',
    String album = 'Oreamnos',
  }) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final request = await Gal.requestAccess(toAlbum: true);
        if (!request) return false;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path, album: album);
      return true;
    } catch (e) {
      throw Exception('Failed to save to gallery: $e');
    }
  }

  /// Shares the captured PNG bytes via the native share dialog.
  Future<void> shareImage(
    List<int> pngBytes, {
    String filename = 'oreamnos_card.png',
    String text = '',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pngBytes);

    final xfile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(files: [xfile], text: text.isEmpty ? null : text),
    );
  }
}
