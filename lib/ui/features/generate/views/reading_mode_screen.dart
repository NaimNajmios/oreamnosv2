import 'package:flutter/material.dart';
import '../../../core/widgets/typewriter_markdown.dart';
import 'package:go_router/go_router.dart';

class ReadingModeScreen extends StatelessWidget {
  final String content;

  const ReadingModeScreen({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 24),
              child: SingleChildScrollView(
                child: TypewriterMarkdown(
                  data: content,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withAlpha(200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

