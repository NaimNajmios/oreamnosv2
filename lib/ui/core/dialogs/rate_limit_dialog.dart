import 'package:flutter/material.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

class RateLimitDialog extends StatelessWidget {
  const RateLimitDialog({
    super.key,
    this.suggestedFallbackProvider,
    this.currentProviderName,
    this.onRetryWithFallback,
  });

  final AiProvider? suggestedFallbackProvider;
  final String? currentProviderName;
  final VoidCallback? onRetryWithFallback;

  static Future<void> show(
    BuildContext context, {
    AiProvider? suggestedFallbackProvider,
    String? currentProviderName,
    VoidCallback? onRetryWithFallback,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RateLimitDialog(
        suggestedFallbackProvider: suggestedFallbackProvider,
        currentProviderName: currentProviderName,
        onRetryWithFallback: onRetryWithFallback,
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
      content: Text(
        hasFallback
            ? '$current is currently overloaded (quota exhausted).\n\nRetry with ${suggestedFallbackProvider!.displayName} instead? Your input is preserved.'
            : 'The API provider is currently overloaded or you have hit your rate limit.\n\nPlease wait a moment and try again, or switch to a different API provider in Settings.',
        style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
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
