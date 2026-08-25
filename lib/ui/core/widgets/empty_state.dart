import 'package:flutter/material.dart';
import 'app_button.dart';

/// Pure Sciuro empty state widget:
/// Centered column, 32dp outer padding, 80dp outlined icon at 50% opacity,
/// 24dp gap, bodyLarge message in onSurfaceVariant, and an optional primary CTA button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryIconColor = iconColor ?? colorScheme.onSurface; // Stark monochrome

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stark 100% opacity Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: primaryIconColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title.toUpperCase(),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '> ${description.toUpperCase()}', // Terminal-style prefix
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Mono', // Monospace override
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              AppButton(
                label: actionLabel!,
                height: 48,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

