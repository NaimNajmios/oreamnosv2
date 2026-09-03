import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
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
    final reduceMotion = AppMotion.shouldReduceMotion(context);

    Widget card = AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: AppColors.error,
      backgroundColor: theme.colorScheme.surface,
      // Whole card scrolls: icon + title + message + button together can
      // exceed short fixed-height parents (e.g. the model dialog), and a
      // scroll view is safe in both bounded and unbounded parents.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: AppColors.error, size: 24),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
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
      ),
    );

    if (reduceMotion) return card;
    // Entrance fade+slide; icon container gets one shake on mount.
    return card
        .animate()
        .fadeIn(duration: AppMotion.transitionSpec)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: AppMotion.transitionSpec,
          curve: AppMotion.curveTransition,
        )
        .shake(duration: const Duration(milliseconds: 400));
  }
}
