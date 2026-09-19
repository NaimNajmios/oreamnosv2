import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_mark.dart';

/// Rate-limit / quota-exhausted dialog with optional fallback-provider retry.
///
/// Rendered as a tightly constrained custom [Dialog] (fixed max width,
/// header mark as a plain widget instead of `AlertDialog.icon`) so nothing
/// underneath — loading indicators, inline error states — can bleed through
/// or composite over the content.
class RateLimitDialog extends StatelessWidget {
  const RateLimitDialog({
    super.key,
    this.suggestedFallbackProvider,
    this.currentProviderName,
    this.onRetryWithFallback,
    this.waitTimeMessage,
    this.fallbackHasKey = true,
    this.isRetrying = false,
  });

  final AiProvider? suggestedFallbackProvider;
  final String? currentProviderName;
  final VoidCallback? onRetryWithFallback;

  /// Provider-supplied wait hint, e.g. "Retry in 34s" (Android
  /// `RateLimitException.waitTimeMessage` parity).
  final String? waitTimeMessage;

  /// False when the fallback provider has no API key configured — the retry
  /// button is then disabled with an "add key" hint instead of firing a
  /// request that is guaranteed to fail.
  final bool fallbackHasKey;

  /// True while the fallback retry is in flight — buttons disable and the
  /// retry button shows an inline spinner.
  final bool isRetrying;

  static Future<void> show(
    BuildContext context, {
    AiProvider? suggestedFallbackProvider,
    String? currentProviderName,
    VoidCallback? onRetryWithFallback,
    String? waitTimeMessage,
    bool fallbackHasKey = true,
    bool isRetrying = false,
  }) {
    Haptics.error();
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => RateLimitDialog(
        suggestedFallbackProvider: suggestedFallbackProvider,
        currentProviderName: currentProviderName,
        onRetryWithFallback: onRetryWithFallback,
        waitTimeMessage: waitTimeMessage,
        fallbackHasKey: fallbackHasKey,
        isRetrying: isRetrying,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasFallback = suggestedFallbackProvider != null;
    final current = currentProviderName ?? 'Current provider';
    final retryEnabled = hasFallback && fallbackHasKey && !isRetrying;

    final dialog = Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: KickoffMark(size: 56, highlightedIndex: 4)),
              const SizedBox(height: 16),
              Text(
                'Rate Limit Exceeded',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasFallback
                    ? '$current is currently overloaded (quota exhausted).\n\nRetry with ${suggestedFallbackProvider!.displayName} instead? Your input is preserved.'
                    : 'The API provider is currently overloaded or you have hit your rate limit.\n\nPlease wait a moment and try again, or switch to a different API provider in Settings.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              if (waitTimeMessage case final hint?) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _WaitHintChip(waitTimeMessage: hint, colors: colors),
                ),
              ],
              if (hasFallback && !fallbackHasKey) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_off_outlined,
                        size: 16,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add your ${suggestedFallbackProvider!.displayName} key in Settings to use this fallback.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackActions = constraints.maxWidth < 340;
                  final stayButton = TextButton(
                    onPressed: isRetrying
                        ? null
                        : () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                    child: Text(hasFallback ? 'Stay on $current' : 'Got it'),
                  );
                  if (!hasFallback) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: stayButton,
                    );
                  }
                  final retryButton = FilledButton(
                    onPressed: !retryEnabled
                        ? null
                        : () {
                            Navigator.of(context, rootNavigator: true).pop();
                            onRetryWithFallback?.call();
                          },
                    child: isRetrying
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: KickoffLoadingIndicator(size: 16),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  'Retrying…',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Retry with ${suggestedFallbackProvider!.displayName}',
                          ),
                  );
                  if (stackActions) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        retryButton,
                        const SizedBox(height: 4),
                        stayButton,
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(child: stayButton),
                      const SizedBox(width: 8),
                      Flexible(child: retryButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (AppMotion.shouldReduceMotion(context)) return dialog;
    // Single gentle entrance — no shake loop that can composite oddly over
    // the content or keep the tree dirty in tests.
    return dialog
        .animate()
        .fadeIn(duration: AppMotion.micro)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.transitionSpec,
          curve: AppMotion.curveTransition,
        );
  }
}

/// Wait-hint chip with a gentle pulse (suppressed in tests / reduced motion
/// so `pumpAndSettle` can settle).
class _WaitHintChip extends StatelessWidget {
  const _WaitHintChip({required this.waitTimeMessage, required this.colors});

  final String waitTimeMessage;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty_rounded, size: 16),
          const SizedBox(width: 6),
          Text(
            waitTimeMessage,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (AppMotion.shouldSuppressAmbient(context)) return chip;
    return chip
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: AppMotion.breathing)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          duration: AppMotion.breathing,
        );
  }
}
