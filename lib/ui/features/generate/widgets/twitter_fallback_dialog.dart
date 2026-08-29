import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TwitterFallbackDialog extends StatefulWidget {
  const TwitterFallbackDialog({super.key, required this.originalUrl});
  final String originalUrl;

  @override
  State<TwitterFallbackDialog> createState() => _TwitterFallbackDialogState();
}

class _TwitterFallbackDialogState extends State<TwitterFallbackDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _controller.text = data.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('X/Twitter Post Detected'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'X restricts direct content extraction. Please paste the tweet text below:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste tweet text here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.paste),
              label: const Text('Paste from Clipboard'),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: In X, tap "..." on the tweet → "Copy text"',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.isNotEmpty
              ? () {
                  Navigator.pop(context, _controller.text);
                }
              : null,
          child: const Text('Use This Text'),
        ),
      ],
    );
  }
}
