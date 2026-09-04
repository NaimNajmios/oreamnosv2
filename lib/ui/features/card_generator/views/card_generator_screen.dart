import 'dart:ui' as dart_ui;

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
                  // Preset background handling (as in original)
                  if (state.backgroundType == BackgroundType.preset &&
                      state.presetBackground != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: _presetGradient(state.presetBackground!),
                      ),
                    )
                  else if (state.backgroundImage != null)
                    _buildBackgroundByPosition(state),
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

  Widget _buildBackgroundByPosition(CardGeneratorState state) {
    final img = _wrapWithOpacityAndBlur(
      opacity: state.imageOpacity,
      blur: state.backgroundBlurRadius,
      child: _applyPhotoFilter(
        state.photoFilter,
        Image.file(state.backgroundImage!, fit: BoxFit.cover),
      ),
    );
    switch (state.imagePosition) {
      case ImagePosition.splitLeft:
        return Row(
          children: [
            Expanded(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.5,
                maxScale: 4.0,
                child: img,
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        );
      case ImagePosition.splitRight:
        return Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.5,
                maxScale: 4.0,
                child: img,
              ),
            ),
          ],
        );
      case ImagePosition.overlayTop:
        return Column(
          children: [
            SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: img,
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        );
      case ImagePosition.minimal:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 200, height: 200, child: img),
            ),
          ),
        );
      case ImagePosition.cutout:
        return Center(
          child: Padding(padding: const EdgeInsets.all(16), child: img),
        );
      case ImagePosition.magazineBold:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: img),
        );
      case ImagePosition.offsetCard:
        return Align(
          alignment: const Alignment(0.2, -0.2),
          child: FractionallySizedBox(
            widthFactor: 0.9,
            heightFactor: 0.85,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: img,
            ),
          ),
        );
      case ImagePosition.brutalist:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: img,
        );
      case ImagePosition.floatWindow:
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 140, height: 140, child: img),
            ),
          ),
        );
      case ImagePosition.background:
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.5,
          maxScale: 4.0,
          child: img,
        );
    }
  }

  Widget _wrapWithOpacityAndBlur({
    required double opacity,
    required double blur,
    required Widget child,
  }) {
    Widget w = child;
    if (opacity < 0.99) {
      w = Opacity(opacity: opacity, child: w);
    }
    if (blur > 0.1) {
      w = ImageFiltered(
        imageFilter: dart_ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: w,
      );
    }
    return w;
  }

  LinearGradient _presetGradient(PresetBackground preset) {
    return switch (preset) {
      PresetBackground.stadiumBlur => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF334155)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      PresetBackground.darkMesh => const LinearGradient(
        colors: [Color(0xFF111827), Color(0xFF1F2937)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      PresetBackground.grassTexture => const LinearGradient(
        colors: [Color(0xFF14532D), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    };
  }

  Widget _applyPhotoFilter(PhotoFilter filter, Widget child) {
    switch (filter) {
      case PhotoFilter.vibrant:
        // Saturation boost 1.8 via color matrix approximated
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.4,
            -0.2,
            -0.2,
            0,
            0,
            -0.2,
            1.4,
            -0.2,
            0,
            0,
            -0.2,
            -0.2,
            1.4,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.highContrast:
        // High contrast matrix
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.5,
            0,
            0,
            0,
            -20,
            0,
            1.5,
            0,
            0,
            -20,
            0,
            0,
            1.5,
            0,
            -20,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.blackWhite:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.vintage:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.393,
            0.769,
            0.189,
            0,
            0,
            0.349,
            0.686,
            0.168,
            0,
            0,
            0.272,
            0.534,
            0.131,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.none:
        return child;
    }
  }
}

class _WatermarkOverlay extends StatelessWidget {
  final dynamic state;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;

  const _WatermarkOverlay({
    required this.state,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
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
            Positioned(
              left: dx * w - size / 2,
              top: dy * h - size / 2,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final newDx = (dx * w + details.delta.dx) / w;
                  final newDy = (dy * h + details.delta.dy) / h;
                  onDragUpdate(Offset(newDx, newDy));
                },
                onPanEnd: (_) => onDragEnd(offset),
                child: Opacity(opacity: 0.92, child: content),
              ),
            ),
          ],
        );
      },
    );
  }
}
