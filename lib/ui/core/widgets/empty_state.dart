import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:oreamnos/config/theme/app_motion.dart';

import 'app_button.dart';
import 'kickoff_mark.dart';

/// Empty-state illustration style.
enum EmptyIllustrationStyle { icon, kickoff }

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
    this.illustration,
    this.illustrationStyle = EmptyIllustrationStyle.icon,
    this.kickoffAccentIndex = -1,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBackground;
  final Widget? illustration;
  final EmptyIllustrationStyle illustrationStyle;
  final int kickoffAccentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryIconColor =
        iconColor ?? colorScheme.onSurface; // Stark monochrome

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or icon (kickoff motif or legacy icon).
            if (illustration != null)
              SizedBox(width: 120, height: 120, child: illustration!)
            else if (illustrationStyle == EmptyIllustrationStyle.kickoff)
              _KickoffIllustration(accentIndex: kickoffAccentIndex)
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      iconBackground ??
                      colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: primaryIconColor),
              ),
            const SizedBox(height: 32),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              AppButton(label: actionLabel!, height: 48, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Breathing kickoff illustration (skipped when reduced motion is on).
class _KickoffIllustration extends StatelessWidget {
  const _KickoffIllustration({this.accentIndex = -1});

  final int accentIndex;

  @override
  Widget build(BuildContext context) {
    final mark = KickoffMark(
      size: 120,
      highlightedIndex: accentIndex,
    );
    if (AppMotion.shouldSuppressAmbient(context)) return mark;
    return mark
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(
          begin: 0,
          end: -4,
          duration: AppMotion.breathing,
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: AppMotion.transitionSpec);
  }
}
