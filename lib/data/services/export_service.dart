import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// Captures the widget inside the RepaintBoundary with the given GlobalKey
  /// and returns it as a PNG byte array.
  Future<List<int>> capturePng(GlobalKey boundaryKey, {double pixelRatio = 3.0}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Could not find RenderRepaintBoundary for the given key.');
    }

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to convert image to byte data.');
    }
    
    return byteData.buffer.asUint8List();
  }

  /// Saves the captured PNG bytes to the device's gallery.
  Future<bool> saveToGallery(List<int> pngBytes, {String filename = 'oreamnos_card.png'}) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final request = await Gal.requestAccess(toAlbum: true);
        if (!request) return false;
      }
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pngBytes);
      
      await Gal.putImage(file.path);
      return true;
    } catch (e) {
      throw Exception('Failed to save to gallery: $e');
    }
  }

  /// Shares the captured PNG bytes via the native share dialog.
  Future<void> shareImage(List<int> pngBytes, {String filename = 'oreamnos_card.png', String text = ''}) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pngBytes);

    final xfile = XFile(file.path);
    await Share.shareXFiles([xfile], text: text);
  }
}

