import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/generate_provider.dart';
import '../../../core/providers/settings_provider.dart';

class RateLimitDialog extends ConsumerWidget {
  const RateLimitDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generateProvider);
    final settings = ref.watch(settingsProvider);
    final current = settings.selectedProvider;
    final fallback = state.suggestedFallbackProvider;

    return AlertDialog(
      title: const Text('Rate limited'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate limit exceeded for ${current.displayName}.'),
          if (fallback != null) ...[
            const SizedBox(height: 12),
            Text('Try ${fallback.displayName} instead?'),
            const SizedBox(height: 8),
            Text('Fallback chain: Gemini → Groq → OpenRouter → Cerebras → Gemini', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Wait')),
        if (fallback != null)
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(generateProvider.notifier).retryWithProvider(fallback);
            },
            child: Text('Switch to ${fallback.displayName}'),
          ),
      ],
    );
  }

  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final state = ref.read(generateProvider);
    if (state.status != GenerateStatus.rateLimited) return;
    await showDialog(context: context, builder: (_) => const RateLimitDialog());
  }
}
