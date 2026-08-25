import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/config/theme/app_typography.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'app_card.dart';

enum LoadingType {
  extracting,
  generating,
}

class EnhancedLoadingCard extends StatefulWidget {
  const EnhancedLoadingCard({
    super.key,
    this.type = LoadingType.generating,
    this.customMessage,
  });

  final LoadingType type;
  final String? customMessage;

  @override
  State<EnhancedLoadingCard> createState() => _EnhancedLoadingCardState();
}

class _EnhancedLoadingCardState extends State<EnhancedLoadingCard> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();

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
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getStatusText(double progress) {
    if (widget.customMessage != null) return widget.customMessage!;
    if (widget.type == LoadingType.extracting) {
      if (progress < 0.4) return 'Fetching article URL...';
      if (progress < 0.8) return 'Parsing article contents...';
      return 'Extracting clean text...';
    } else {
      if (progress < 0.3) return 'Initializing prompt...';
      if (progress < 0.7) return 'Synthesizing post with AI...';
      return 'Almost ready...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = AppMotion.shouldReduceMotion(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnimation, _pulseAnimation]),
        builder: (context, child) {
          final progressVal = _progressAnimation.value;
          final percent = (progressVal * 100).toInt();
          final pulseScale = reduceMotion ? 1.0 : _pulseAnimation.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pulseScale,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      KickoffLoadingIndicator(
                        size: 80,
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        foregroundColor: widget.type == LoadingType.extracting
                              ? (isDark ? AppColors.darkTeal : AppColors.lightTeal)
                              : theme.colorScheme.primary,
                      ),
                      Text(
                        '$percent%',
                        style: AppTypography.mono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _getStatusText(progressVal),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.type == LoadingType.extracting
                    ? 'Extracting clean article data & metadata'
                    : 'Transforming text into Serene Editorial content',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StageDot(
                    isActive: widget.type == LoadingType.extracting || progressVal >= 0.1,
                    isDone: widget.type == LoadingType.generating,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _StageDot(
                    isActive: widget.type == LoadingType.generating && progressVal >= 0.4,
                    isDone: progressVal >= 0.85,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _StageDot(
                    isActive: progressVal >= 0.85,
                    isDone: false,
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({
    required this.isActive,
    required this.isDone,
    required this.color,
  });

  final bool isActive;
  final bool isDone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success
            : (isActive ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
        shape: BoxShape.circle,
      ),
    );
  }
}