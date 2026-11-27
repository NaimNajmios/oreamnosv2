import 'package:flutter/services.dart';

/// Verifies that every bundled card font asset is present before export.
abstract final class FontPreflight {
  static const List<String> assets = [
    'assets/fonts/BigShouldersDisplay-Variable.ttf',
    'assets/fonts/Inter-Variable.ttf',
    'assets/fonts/Inter-Italic-Variable.ttf',
    'assets/fonts/Lora-Variable.ttf',
    'assets/fonts/Lora-Italic-Variable.ttf',
    'assets/fonts/SpaceMono-Regular.ttf',
    'assets/fonts/SpaceMono-Bold.ttf',
    'assets/fonts/SpaceMono-Italic.ttf',
    'assets/fonts/SpaceMono-BoldItalic.ttf',
  ];

  /// Returns the asset paths that failed to load. Empty means preflight passed.
  static Future<List<String>> missingAssets() async {
    final missing = <String>[];
    for (final path in assets) {
      try {
        final data = await rootBundle.load(path);
        if (data.lengthInBytes == 0) missing.add(path);
      } catch (_) {
        missing.add(path);
      }
    }
    return missing;
  }
}
