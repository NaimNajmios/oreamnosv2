import 'package:flutter/material.dart';

import '../../../../../domain/services/contrast_guard.dart';

/// Editor-only warning when the accent colour does not meet text contrast.
class ContrastBadge extends StatelessWidget {
  const ContrastBadge({
    super.key,
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final ratio = ContrastGuard.ratio(foreground, background);
    final ok = ContrastGuard.isReadable(foreground, background);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ok
            ? 'Contrast ${ratio.toStringAsFixed(1)}:1'
            : 'Low contrast ${ratio.toStringAsFixed(1)}:1',
        style: TextStyle(
          color: ok ? const Color(0xFF32D74B) : const Color(0xFFFFB020),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
