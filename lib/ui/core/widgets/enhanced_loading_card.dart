import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';

import 'app_card.dart';

/// The real pipeline step shown by the loading card.
///
/// Copy is deliberately plain-language. "Serene Editorial" is an internal
/// design-system name and must never be presented to the user.
enum LoadingStage { readingLink, researching, writing, polishing }

class EnhancedLoadingCard extends StatefulWidget {
  const EnhancedLoadingCard({super.key, required this.stage, this.notice});

  /// The actual step the generation pipeline is currently in.
  final LoadingStage stage;

  /// A transient status such as a rate-limit fallback. When present it becomes
  /// the title and suppresses the stage subtitle, so the two can never
  /// contradict each other.
  final String? notice;

  @override
  State<EnhancedLoadingCard> createState() => _EnhancedLoadingCardState();
}

class _EnhancedLoadingCardState extends State<EnhancedLoadingCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Gentle breathing motion only; there is no fake progress sweep. Real
    // requests can take up to ~90s, so any percentage would be a lie that
    // strands the user at "Finalizing…" for most of the wait.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _hasNotice =>
      widget.notice != null && widget.notice!.trim().isNotEmpty;

  String get _title {
    if (_hasNotice) return widget.notice!;
    return switch (widget.stage) {
      LoadingStage.readingLink => 'Reading your link…',
      LoadingStage.researching => 'Researching with AI…',
      LoadingStage.writing => 'Writing your post…',
      LoadingStage.polishing => 'Polishing your card…',
    };
  }

  String get _subtitle {
    if (_hasNotice) return 'Still working — this can take a moment.';
    return switch (widget.stage) {
      LoadingStage.readingLink =>
        'Fetching the page and pulling out the article text.',
      LoadingStage.researching =>
        'Gathering extra context to make the post sharper.',
      LoadingStage.writing =>
        'Turning the source into a ready-to-publish caption.',
      LoadingStage.polishing => 'Tidying up the layout and text.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    final foregroundColor = widget.stage == LoadingStage.writing
        ? theme.colorScheme.primary
        : (isDark ? AppColors.darkTeal : AppColors.lightTeal);
    final title = _title;
    final subtitle = _subtitle;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseScale = reduceMotion ? 1.0 : _pulseAnimation.value;

          return Semantics(
            label: '$title $subtitle',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: pulseScale,
                  child: KickoffLoadingIndicator(
                    size: 80,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.05,
                    ),
                    foregroundColor: foregroundColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
