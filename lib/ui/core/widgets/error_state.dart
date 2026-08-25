import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Error indicator card with retry button.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Generation Error',
    required this.message,
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: AppColors.error,
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.error, width: 2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.error, size: 24),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '> ERROR:\n$message',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'IBM Plex Mono',
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: retryLabel,
              height: 48,
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
