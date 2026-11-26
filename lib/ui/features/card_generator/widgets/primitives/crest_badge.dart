import 'dart:io';

import 'package:flutter/material.dart' hide CardTheme;

import '../../../../../config/theme/card_fonts.dart';
import '../../../../../config/theme/card_theme.dart';

/// A user-supplied crest with a deterministic monogram fallback.
///
/// No club or league marks are bundled with the app â€” [imagePath] must come
/// from the user's own media library.
class CrestBadge extends StatelessWidget {
  const CrestBadge({
    super.key,
    this.imagePath,
    required this.label,
    this.size = 22,
    this.color,
  });

  final String? imagePath;
  final String label;
  final double size;
  final Color? color;

  static String monogram(String label) {
    final words = label.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return 'O';
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length > 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _Monogram(label: label, size: size, color: color),
          ),
        );
      }
    }
    return _Monogram(label: label, size: size, color: color);
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({
    required this.label,
    required this.size,
    required this.color,
  });

  final String label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (color ?? CardTheme.warningColor).withValues(alpha: 0.18),
        border: Border.all(
          color: (color ?? CardTheme.warningColor).withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Text(
        CrestBadge.monogram(label),
        style: CardFonts.jetBrainsMono(
          color: color ?? CardTheme.warningColor,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
