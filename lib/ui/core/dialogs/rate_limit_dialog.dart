import 'package:flutter/material.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

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

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          if (waitTimeMessage != null) ...[
            const SizedBox(height: 12),
            Container(
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
                    waitTimeMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
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
  }
}
