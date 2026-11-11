import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';

/// Non-blocking notice for a connection that needs attention.
///
/// An expired token asks for a reconnect; a transport failure only explains
/// that drafts are safe and offers a manual retry. The banner never blocks
/// editing or scheduling.
class FacebookConnectionBanner extends StatelessWidget {
  const FacebookConnectionBanner({
    super.key,
    required this.offline,
    required this.expired,
    this.onRetry,
    this.onReconnect,
  });

  final bool offline;
  final bool expired;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    if (!offline && !expired) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final background = expired
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final foreground = expired
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;
    final title = expired
        ? 'Page connection needs attention'
        : "You're offline";
    final message = expired
        ? 'Reconnect your Page before publishing. Drafts are safe.'
        : 'Drafts are safe. Publishing works again once the connection returns.';
    final action = expired ? onReconnect : onRetry;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              expired ? Icons.key_off_rounded : Icons.cloud_off_rounded,
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: action,
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(expired ? 'Reconnect' : 'Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
