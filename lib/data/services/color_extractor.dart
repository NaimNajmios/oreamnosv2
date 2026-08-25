import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorExtractor {
  static const Map<String, List<Color>> clubColorMap = {
    'jdt': [Color(0xFF0D47A1), Color(0xFFB71C1C)],
    'johor': [Color(0xFF0D47A1), Color(0xFFB71C1C)],
    'selangor': [Color(0xFFB71C1C), Color(0xFFFFEB3B)],
    'pahang': [Color(0xFFFFEB3B), Color(0xFF212121)],
    'sri pahang': [Color(0xFFFFEB3B), Color(0xFF212121)],
    'kedah': [Color(0xFF1B5E20), Color(0xFFFFEB3B)],
    'perak': [Color(0xFFFFEB3B), Color(0xFF212121)],
    'terengganu': [Color(0xFF212121), Color(0xFFFFFFFF)],
    'sabah': [Color(0xFFB71C1C), Color(0xFF1B5E20)],
    'pdrm': [Color(0xFF0D47A1), Color(0xFFFFEB3B)],
    'kuala lumpur': [Color(0xFFB71C1C), Color(0xFF0D47A1)],
    'klcity': [Color(0xFFB71C1C), Color(0xFF0D47A1)],
    'negeri sembilan': [Color(0xFFB71C1C), Color(0xFFFFEB3B)],
    'malaysia': [Color(0xFFFFEB3B), Color(0xFFB71C1C)],
    'harimau': [Color(0xFFFFEB3B), Color(0xFF212121)],
  };

  static const List<List<Color>> presetSwatches = [
    [Color(0xFF1A237E), Color(0xFF0D47A1)],
    [Color(0xFF880E4F), Color(0xFFE11D48)],
    [Color(0xFF004D40), Color(0xFF00695C)],
    [Color(0xFF4A148C), Color(0xFF6A1B9A)],
    [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    [Color(0xFFF57F17), Color(0xFFFF8F00)],
  ];

  static List<Color> getColorsForTeam(String team) {
    final key = team.toLowerCase().trim();
    for (final e in clubColorMap.entries) {
      if (key.contains(e.key)) return e.value;
    }
    return presetSwatches.first;
  }

  static List<Color> getMatchColors(String home, String away) {
    final homeColors = getColorsForTeam(home);
    final awayColors = getColorsForTeam(away);
    // Blend primary colors
    return [homeColors.first, awayColors.first];
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

  static Future<List<Color>?> _extractViaPaletteGenerator(String imagePath) async {
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
      if (vibrant != null && dominant != null && vibrant != dominant) return [vibrant, dominant];
      if (vibrant != null) return [vibrant, vibrant.withValues(alpha: 0.7)];
      if (darkVibrant != null) return [darkVibrant, darkVibrant.withValues(alpha: 0.7)];
      if (dominant != null) return [dominant, dominant.withValues(alpha: 0.7)];
      return null;
    } catch (_) {
      return null;
    }
  }
}
