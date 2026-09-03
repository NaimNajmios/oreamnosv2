import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Named gradient preset shown in the BackgroundPickerSheet gradient tab.
class PresetSwatch {
  const PresetSwatch(this.name, this.colors);
  final String name;
  final List<Color> colors;
}

class ColorExtractor {
  /// Exact port of Android `ColorExtractor.clubColorMap` — order matters:
  /// partial matching returns the first keyword contained in the team name.
  static const Map<String, List<Color>> clubColorMap = {
    'jdt': [Color(0xFFFFD100), Color(0xFF003087)],
    'johor': [Color(0xFFFFD100), Color(0xFF003087)],
    'selangor': [Color(0xFFD21034), Color(0xFF1A0A00)],
    'pahang': [Color(0xFF1A1A1A), Color(0xFFFFC200)],
    'kedah': [Color(0xFFCC0000), Color(0xFF7A0000)],
    'perak': [Color(0xFF4A90D9), Color(0xFFC0C0C0)],
    'terengganu': [Color(0xFF006994), Color(0xFF002D55)],
    'sabah': [Color(0xFF003580), Color(0xFF001F4D)],
    'pdrm': [Color(0xFF003087), Color(0xFF001A52)],
    'kuala lumpur': [Color(0xFF8B0000), Color(0xFF3A0000)],
    'klcity': [Color(0xFF8B0000), Color(0xFF3A0000)],
    'sri pahang': [Color(0xFF2D2D2D), Color(0xFFB8860B)],
    'negeri sembilan': [Color(0xFFFFD700), Color(0xFF8B0000)],
    'malaysia': [Color(0xFFCC0001), Color(0xFF003087)],
    'harimau': [Color(0xFFCC0001), Color(0xFF003087)],
  };

  /// The six named preset swatches from the BackgroundPickerSheet gradient tab.
  static const List<PresetSwatch> presetSwatches = [
    PresetSwatch('JDT', [Color(0xFFFFD100), Color(0xFF003087)]),
    PresetSwatch('Selangor', [Color(0xFFD21034), Color(0xFF1A0A00)]),
    PresetSwatch('Pahang', [Color(0xFF1A1A1A), Color(0xFFFFC200)]),
    PresetSwatch('Kedah', [Color(0xFFCC0000), Color(0xFF7A0000)]),
    PresetSwatch('Perak', [Color(0xFF4A90D9), Color(0xFFC0C0C0)]),
    PresetSwatch('Malaysia', [Color(0xFFCC0001), Color(0xFF003087)]),
  ];

  static List<Color> getColorsForTeam(String team) {
    final key = team.toLowerCase().trim();
    for (final e in clubColorMap.entries) {
      if (key.contains(e.key)) return e.value;
    }
    return presetSwatches.first.colors;
  }

  /// Home team's gradient start + away team's gradient end (Android parity).
  static List<Color> getMatchColors(String home, String away) {
    final homeColors = getColorsForTeam(home);
    final awayColors = getColorsForTeam(away);
    return [homeColors.first, awayColors.last];
  }

  static Future<List<Color>?> extractPalette(String imagePath) async {
    try {
      // ignore: depend_on_referenced_packages
      // Use palette_generator if available; otherwise fallback to null
      // This is now enabled per Phase D (cached_network_image + palette_generator added)
      return await _extractViaPaletteGenerator(imagePath);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Color>?> _extractViaPaletteGenerator(
    String imagePath,
  ) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      final provider = ResizeImage(FileImage(file), width: 200);
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 16,
      );
      final vibrant = palette.vibrantColor?.color;
      final darkVibrant = palette.darkVibrantColor?.color;
      final dominant = palette.dominantColor?.color;
      if (vibrant != null && darkVibrant != null) return [vibrant, darkVibrant];
      if (vibrant != null && dominant != null && vibrant != dominant) {
        return [vibrant, dominant];
      }
      if (vibrant != null) {
        return [vibrant, vibrant.withValues(alpha: 0.7)];
      }
      if (darkVibrant != null) {
        return [darkVibrant, darkVibrant.withValues(alpha: 0.7)];
      }
      if (dominant != null) return [dominant, dominant.withValues(alpha: 0.7)];
      return null;
    } catch (_) {
      return null;
    }
  }
}
