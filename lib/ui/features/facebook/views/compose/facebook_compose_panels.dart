import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';

/// Publish failure panel with retry/reconnect.
class FacebookErrorPanel extends StatelessWidget {
  const FacebookErrorPanel({
    super.key,
    required this.message,
    required this.needsReconnect,
    required this.onRetry,
    required this.onReconnect,
  });

  final String message;
  final bool needsReconnect;
  final VoidCallback onRetry;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      borderRadius: AppSpacing.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          needsReconnect
              ? TextButton.icon(
                  onPressed: onReconnect,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reconnect Page'),
                )
              : TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
        ],
      ),
    );
  }
}

/// “The write may have landed” panel: verify before retrying.
class FacebookUncertainPanel extends StatelessWidget {
  const FacebookUncertainPanel({
    super.key,
    required this.message,
    required this.onViewPublished,
    required this.onViewScheduled,
    required this.onRetry,
    required this.onDiscard,
  });

  final String message;
  final VoidCallback onViewPublished;
  final VoidCallback onViewScheduled;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      borderRadius: AppSpacing.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'We didn’t get a confirmation from Facebook. The post may or may '
            'not be live. Check Published before trying again.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              TextButton(
                onPressed: onViewPublished,
                child: const Text('View Published'),
              ),
              TextButton(
                onPressed: onViewScheduled,
                child: const Text('View Scheduled'),
              ),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
              TextButton(
                onPressed: onDiscard,
                child: Text(
                  'Discard',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
