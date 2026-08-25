import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/app_colors.dart';

/// Minimal success overlay — shows checkmark + fade.
/// Persistent only on first generate (per user: "Only on the first generate").
class SuccessOverlay extends StatelessWidget {
  const SuccessOverlay({super.key, required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onDismiss,
        child: Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
            ),
            child: const Icon(Icons.check_rounded, size: 64, color: AppColors.success),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut).fadeIn(duration: 200.ms),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).fadeOut(delay: 1200.ms, duration: 300.ms, curve: Curves.easeOut);
  }
}
