import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_mark.dart';

class RateLimitDialog extends StatelessWidget {
  const RateLimitDialog({
    super.key,
    this.suggestedFallbackProvider,
    this.currentProviderName,
    this.onRetryWithFallback,
    this.waitTimeMessage,
  });

  final AiProvider? suggestedFallbackProvider;
  final String? currentProviderName;
  final VoidCallback? onRetryWithFallback;

  /// Provider-supplied wait hint, e.g. "Retry in 34s" (Android
  /// `RateLimitException.waitTimeMessage` parity).
  final String? waitTimeMessage;

  static Future<void> show(
    BuildContext context, {
    AiProvider? suggestedFallbackProvider,
    String? currentProviderName,
    VoidCallback? onRetryWithFallback,
    String? waitTimeMessage,
  }) {
    Haptics.error();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RateLimitDialog(
        suggestedFallbackProvider: suggestedFallbackProvider,
        currentProviderName: currentProviderName,
        onRetryWithFallback: onRetryWithFallback,
        waitTimeMessage: waitTimeMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasFallback = suggestedFallbackProvider != null;
    final current = currentProviderName ?? 'Current provider';

    Widget dialog = AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const KickoffMark(size: 56, highlightedIndex: 4),
      title: const Text(
        'Rate Limit Exceeded',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasFallback
                ? '$current is currently overloaded (quota exhausted).\n\nRetry with ${suggestedFallbackProvider!.displayName} instead? Your input is preserved.'
                : 'The API provider is currently overloaded or you have hit your rate limit.\n\nPlease wait a moment and try again, or switch to a different API provider in Settings.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
          if (waitTimeMessage case final hint?) ...[
            const SizedBox(height: 12),
            _WaitHintChip(waitTimeMessage: hint, colors: colors),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(hasFallback ? 'Stay on $current' : 'Got it'),
        ),
        if (hasFallback)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetryWithFallback?.call();
            },
            child: Text('Retry with ${suggestedFallbackProvider!.displayName}'),
          ),
      ],
    );

    if (AppMotion.shouldReduceMotion(context)) return dialog;
    // Entrance scale + one shake to signal the 429.
    return dialog
        .animate()
        .fadeIn(duration: AppMotion.micro)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.transitionSpec,
          curve: AppMotion.curveTransition,
        )
        .shake(duration: const Duration(milliseconds: 400));
  }
}

/// Wait-hint chip with a gentle pulse (suppressed in tests / reduced motion
/// so `pumpAndSettle` can settle).
class _WaitHintChip extends StatelessWidget {
  const _WaitHintChip({required this.waitTimeMessage, required this.colors});

  final String waitTimeMessage;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty_rounded, size: 16),
          const SizedBox(width: 6),
          Text(
            waitTimeMessage,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (AppMotion.shouldSuppressAmbient(context)) return chip;
    return chip
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: AppMotion.breathing)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          duration: AppMotion.breathing,
        );
  }
}
