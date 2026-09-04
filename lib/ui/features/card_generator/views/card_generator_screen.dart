import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_snackbar.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_mark.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';
import 'package:oreamnos/ui/core/widgets/enhanced_loading_card.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

import '../../generate/view_models/generate_view_model.dart';
import '../view_models/card_generator_view_model.dart';
import '../view_models/card_generator_state.dart';
import '../widgets/card_stage.dart';
import '../widgets/renderers/card_canvas_dispatcher.dart';
import '../widgets/card_background_renderer.dart';

import 'package:oreamnos/domain/models/card_config.dart';

import '../widgets/picsart_tool_dock.dart';
import '../widgets/export_bottom_sheet.dart';
import '../widgets/studio_deck_sheet.dart';

/// Card Studio — now Riverpod Consumer + legacy ViewModel hybrid (incremental).
/// Supports sealed 16-variant CardData via new dispatcher when available.
class CardGeneratorScreen extends ConsumerStatefulWidget {
  final CardBrief brief;
  final bool hasError;

  const CardGeneratorScreen({
    super.key,
    required this.brief,
    this.hasError = false,
  });

  @override
  ConsumerState<CardGeneratorScreen> createState() =>
      _CardGeneratorScreenState();
}

class _CardGeneratorScreenState extends ConsumerState<CardGeneratorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  late CardBrief _activeBrief;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _activeBrief = widget.brief;
    _hasError = widget.hasError;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_hasError) return;

      // Auto-load from GenerateViewModel if brief is empty
      if (_activeBrief.isEmpty) {
        final generateVm = ref.read(generateViewModelProvider.notifier);
        if (generateVm.curatedPost != null) {
          final settings = ref.read(settingsViewModelProvider);
          final fallbackModel = settings.selectedModel?.isNotEmpty ?? false
              ? settings.selectedModel!
              : settings.selectedProvider.defaultModelId;
          _activeBrief = CardBrief.fromPost(
            title: generateVm.curatedPost!.title,
            bodyMarkdown: generateVm.curatedPost!.bodyMarkdown,
            provider: settings.selectedProvider,
            modelId: fallbackModel,
          );
        }
      }

      if (_activeBrief.isEmpty) return;

      String apiKey = '';
      try {
        apiKey =
            await ref
                .read(settingsViewModelProvider.notifier)
                .getApiKeyForProvider(_activeBrief.provider) ??
            '';
        if (apiKey.isEmpty) {
          if (!mounted) return;
          apiKey =
              await ref
                  .read(settingsViewModelProvider.notifier)
                  .getApiKeyForProvider(_activeBrief.provider) ??
              '';
        }
      } catch (_) {}
      if (!mounted) return;
      await ref
          .read(cardGeneratorViewModelProvider.notifier)
          .initialize(_activeBrief, apiKey);
      setState(() {});
    });
  }

  Future<void> _handleSaveToGallery() async {
    final vm = ref.read(cardGeneratorViewModelProvider.notifier);
    final success = await vm.saveToGallery(_boundaryKey);
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'Card saved to gallery');
    } else {
      AppSnackBar.showError(context, 'Failed to save image');
    }
  }

  Future<void> _handleShare() async {
    final vm = ref.read(cardGeneratorViewModelProvider.notifier);
    AppSnackBar.show(context, 'Preparing share…', icon: Icons.share_rounded);
    final success = await vm.shareCard(_boundaryKey);
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'Share sheet opened');
    } else {
      AppSnackBar.showError(context, 'Failed to share card');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final vm = ref.watch(cardGeneratorViewModelProvider);
        final theme = Theme.of(context);

        // Invalid entry (deep link / empty brief)
        if (_hasError || _activeBrief.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Card Studio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            body: EmptyState(
              title: 'No card data',
              description: 'Go to Generate to create a post first. Your card will appear here automatically.',
              icon: Icons.image_not_supported_rounded,
              illustrationStyle: EmptyIllustrationStyle.kickoff,
              actionLabel: 'Go to Generate',
              onAction: () => context.go(RoutePaths.generate),
            ),
          );
        }

        final hasData = vm.cardData != null;

        return Scaffold(
          appBar: AppBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Center(child: KickoffAppBarMark(size: 28)),
            ),
            title: Text(
              'Card Studio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              if (hasData)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 8,
                  ),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text(
                      'Export',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Haptics.lightImpact();
                      ExportBottomSheet.show(
                        context,
                        onSaveToGallery: _handleSaveToGallery,
                        onShare: _handleShare,
                      );
                    },
                  ),
                ),
            ],
          ),
          body: _buildBody(context, vm, ref, theme, hasData),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CardGeneratorState state,
    WidgetRef ref,
    ThemeData theme,
    bool hasData,
  ) {
    // Extracting — keep stage visible with seeded data if available
    if (state.isExtracting && !hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: EnhancedLoadingCard(
            type: LoadingType.extracting,
            customMessage: 'Polishing card…',
          ),
        ),
      );
    }

    if (state.extractionError != null && !hasData) {
      return ErrorState(
        title: 'Polish Failed',
        message: state.extractionError!,
        retryLabel: 'Retry',
        onRetry: () async {
          String apiKey = '';
          try {
            apiKey =
                await ref
                    .read(settingsViewModelProvider.notifier)
                    .getApiKeyForProvider(widget.brief.provider) ??
                '';
          } catch (_) {}
          ref.read(cardGeneratorViewModelProvider.notifier).extractData(apiKey);
        },
      );
    }

    if (!hasData) {
      return EmptyState(
        icon: Icons.image_not_supported_rounded,
        title: 'Nothing to polish yet',
        description: 'Extraction returned no card data. Retry extraction or go back to Generate.',
        illustrationStyle: EmptyIllustrationStyle.kickoff,
        actionLabel: 'Back to Generate',
        onAction: () => context.go(RoutePaths.generate),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            color: theme.colorScheme.surface,
            child: CardStage(
              boundaryKey: _boundaryKey,
              aspectRatio: state.selectedRatio.ratio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CardBackgroundRenderer(state: state),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: CardCanvasDispatcher(
                      key: ValueKey(state.selectedTemplate),
                      cardData: state.cardData!,
                      config: CardConfig(
                        template: state.selectedTemplate,
                        backgroundType: state.backgroundType,
                        presetBackground: state.presetBackground,
                        fontSizeMultiplier: state.headlineScale,
                        overlayOpacity: state.scrimOpacity,
                        showScrim: true,
                        scrimType: state.backgroundImage != null
                            ? ScrimType.dark
                            : (state.useVignette
                                  ? ScrimType.dark
                                  : ScrimType.minimal),
                        backgroundImagePath: state.backgroundImage?.path,
                        useAutoPalette: state.useAutoPalette,
                        colorPair: state.extractedPalette != null
                            ? [
                                state.extractedPalette!.first,
                                state.extractedPalette!.last,
                              ]
                            : (state.accentColor != null
                                  ? [
                                      state.accentColor!,
                                      state.accentColor!.withValues(alpha: 0.7),
                                    ]
                                  : const [
                                      Color(0xFF1A237E),
                                      Color(0xFF0D47A1),
                                    ]),
                        primaryFontFamilyName:
                            state.selectedFont == AppFont.classicSerif
                            ? 'Lora'
                            : state.selectedFont == AppFont.typewriter
                            ? 'Space Mono'
                            : 'Inter',
                        accentColor: state.accentColor,
                        badgeText: state.badgeText,
                        previewScale: state.previewScale,
                        imageOpacity: state.imageOpacity,
                        backgroundBlurRadius: state.backgroundBlurRadius,
                        textShadowRadius: state.textShadowRadius,
                        textShadowColor:
                            state.textShadowColor ?? const Color(0x80000000),
                        isGlowEnabled: state.isGlowEnabled,
                        brandName: state.brandName,
                        brandHandle: state.brandHandle,
                        showBrandFooter: state.showBrandFooter,
                        isWatermarkEnabled: state.showWatermark,
                        watermarkPath: state.watermarkText,
                        imagePosition: state.imagePosition,
                        photoFilter: state.photoFilter,
                        exportSize: ExportSize.fromRatioName(
                          state.selectedRatio.name,
                        ),
                      ),
                    ),
                  ),
                  // Badge overlay as in original (badgeText)
                  if (state.badgeText != null && state.badgeText!.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (state.accentColor ?? Colors.redAccent),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          state.badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  if (state.isExtracting && hasData)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: EnhancedLoadingCard(
                              type: LoadingType.extracting,
                              customMessage: 'AI Reprocessing…',
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state.showWatermark)
                    _WatermarkOverlay(
                      state: state,
                      onDragUpdate: (offset) => ref
                          .read(cardGeneratorViewModelProvider.notifier)
                          .setWatermarkOffset(offset),
                      onDragEnd: (offset) => ref
                          .read(cardGeneratorViewModelProvider.notifier)
                          .commitWatermarkOffset(offset),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Undo / Redo controls above the dock
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  state.missingFields.isEmpty
                      ? 'Studio Deck'
                      : 'Deck (${state.missingFields.length})',
                ),
                onPressed: !hasData
                    ? null
                    : () => StudioDeckSheet.show(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                icon: const Icon(Icons.undo_rounded, size: 20),
                tooltip: 'Undo',
                onPressed: state.canUndo
                    ? () {
                        Haptics.lightImpact();
                        ref
                            .read(cardGeneratorViewModelProvider.notifier)
                            .undo();
                      }
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                icon: const Icon(Icons.redo_rounded, size: 20),
                tooltip: 'Redo',
                onPressed: state.canRedo
                    ? () {
                        Haptics.lightImpact();
                        ref
                            .read(cardGeneratorViewModelProvider.notifier)
                            .redo();
                      }
                    : null,
              ),
            ],
          ),
        ),
        // New PicsArt-style bottom tool dock
        const PicsartToolDock(),
      ],
    );
  }
}

class _WatermarkOverlay extends StatefulWidget {
  final dynamic state;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;

  const _WatermarkOverlay({
    required this.state,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_WatermarkOverlay> createState() => _WatermarkOverlayState();
}

class _WatermarkOverlayState extends State<_WatermarkOverlay> {
  bool _snappedX = false;
  bool _snappedY = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final hasImage = state.watermarkImage != null;
    final hasText =
        state.watermarkText != null && state.watermarkText!.isNotEmpty;
    if (!hasImage && !hasText) return const SizedBox.shrink();

    final size = (state.watermarkSize as double).clamp(24.0, 160.0);
    final offset = state.watermarkOffset as Offset;

    Widget content;
    if (hasImage) {
      content = Image.file(
        state.watermarkImage!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      final fontSize = (size / 6).clamp(8.0, 28.0);
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          state.watermarkText!,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final dx = offset.dx.clamp(0.05, 0.95);
        final dy = offset.dy.clamp(0.05, 0.95);

        return Stack(
          children: [
            // Visual Snap Guide Lines
            if (_snappedX)
              Positioned(
                left: dx * w,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1.5,
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                ),
              ),
            if (_snappedY)
              Positioned(
                top: dy * h,
                left: 0,
                right: 0,
                child: Container(
                  height: 1.5,
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                ),
              ),

            // Draggable Watermark Content
            Positioned(
              left: dx * w - size / 2,
              top: dy * h - size / 2,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final rawDx = (dx * w + details.delta.dx) / w;
                  final rawDy = (dy * h + details.delta.dy) / h;

                  double newDx = rawDx.clamp(0.05, 0.95);
                  double newDy = rawDy.clamp(0.05, 0.95);
                  bool snapX = false;
                  bool snapY = false;

                  const snapThreshold = 0.025;
                  const anchors = [0.08, 0.5, 0.92];

                  for (final a in anchors) {
                    if ((rawDx - a).abs() < snapThreshold) {
                      newDx = a;
                      snapX = true;
                      break;
                    }
                  }
                  for (final a in anchors) {
                    if ((rawDy - a).abs() < snapThreshold) {
                      newDy = a;
                      snapY = true;
                      break;
                    }
                  }

                  if ((snapX && !_snappedX) || (snapY && !_snappedY)) {
                    Haptics.selectionClick();
                  }

                  setState(() {
                    _snappedX = snapX;
                    _snappedY = snapY;
                  });

                  widget.onDragUpdate(Offset(newDx, newDy));
                },
                onPanEnd: (_) {
                  setState(() {
                    _snappedX = false;
                    _snappedY = false;
                  });
                  widget.onDragEnd(offset);
                },
                child: Opacity(opacity: 0.92, child: content),
              ),
            ),
          ],
        );
      },
    );
  }
}
