import 'package:flutter/material.dart';

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

  // Auto-palette deferred to Phase C per user decision.
  // Keeping stub for future palette_generator integration.
  static Future<List<Color>?> extractPalette(String imagePath) async {
    return null;
  }
}
