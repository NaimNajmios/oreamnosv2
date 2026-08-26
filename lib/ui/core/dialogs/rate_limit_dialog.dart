import 'package:flutter/material.dart';

class RateLimitDialog extends StatelessWidget {
  const RateLimitDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const RateLimitDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Rate Limit Exceeded',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'The API provider is currently overloaded or you have hit your rate limit.\n\nPlease wait a moment and try again, or switch to a different API provider in Settings.',
        style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
