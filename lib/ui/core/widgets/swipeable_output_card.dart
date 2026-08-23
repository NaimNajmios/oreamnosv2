import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'app_card.dart';

class SwipeableOutputCard extends StatelessWidget {
  final String content;
  final Widget child;

  const SwipeableOutputCard({
    super.key,
    required this.content,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: const Key('output_card_dismissible'),
      // Don't actually dismiss the card
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to Copy
          await Clipboard.setData(ClipboardData(text: content));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          }
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left to Share
          // ignore: deprecated_member_use
          Share.share(content);
        }
        return false; // Never dismiss
      },
      background: _buildBackground(theme, Icons.copy, 'Copy', Alignment.centerLeft),
      secondaryBackground: _buildBackground(theme, Icons.share, 'Share', Alignment.centerRight),
      child: AppCard(child: child),
    );
  }

  Widget _buildBackground(ThemeData theme, IconData icon, String label, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(25), 
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

