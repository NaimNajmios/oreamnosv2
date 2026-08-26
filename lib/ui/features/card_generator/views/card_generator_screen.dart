import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

import '../../generate/view_models/generate_view_model.dart';
import '../view_models/card_generator_view_model.dart';
import '../widgets/card_canvas.dart';
import '../widgets/card_stage.dart';
import '../widgets/picsart_tool_dock.dart';
import '../widgets/export_bottom_sheet.dart';

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
          final settings = ref.read(settingsViewModelProvider.notifier);
          if (settings.selectedModel != null) {
            _activeBrief = CardBrief.fromPost(
              title: generateVm.curatedPost!.title,
              bodyMarkdown: generateVm.curatedPost!.bodyMarkdown,
              provider: settings.selectedProvider,
              modelId: settings.selectedModel!,
            );
          }
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
      Haptics.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Card saved to gallery'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
      );
    } else {
      Haptics.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Failed to save image'),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
      );
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
            body: const EmptyState(
              title: 'No card data',
              description: 'Go to Generate to create a post first. Your card will appear here automatically.',
              icon: Icons.image_not_supported_rounded,
            ),
          );
        }

        final hasData = vm.cardData != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Card Studio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.undo_rounded),
                tooltip: 'Undo',
                onPressed: vm.canUndo
                    ? () {
                        Haptics.lightImpact();
                        vm.undo();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo_rounded),
                tooltip: 'Redo',
                onPressed: vm.canRedo
                    ? () {
                        Haptics.lightImpact();
                        vm.redo();
                      }
                    : null,
              ),
              if (hasData)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'Export',
                    onPressed: () {
                      Haptics.lightImpact();
                      ExportBottomSheet.show(
                        context,
                        onSaveToGallery: _handleSaveToGallery,
                        onShare: () => vm.shareCard(_boundaryKey),
                      );
                    },
                  ),
                ),
            ],
          ),
          body: _buildBody(context, vm, theme, hasData),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CardGeneratorViewModel vm,
    ThemeData theme,
    bool hasData,
  ) {
    // Extracting skeleton — keep stage visible with seeded data if available
    if (vm.isExtracting && !hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: KickoffLoadingIndicator(size: 48),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Polishing card…',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI is tightening the headline for visual punch',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.extractionError != null && !hasData) {
      return ErrorState(
        title: 'Polish Failed',
        message: vm.extractionError!,
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
          vm.extractData(apiKey);
        },
      );
    }

    if (!hasData) {
      return const Center(child: Text('No data.'));
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            color: theme.colorScheme.surface, // or black for Picsart feel? Let's stick to theme for now
            child: CardStage(
              boundaryKey: _boundaryKey,
              aspectRatio: vm.selectedRatio.ratio,
              child: CardCanvas(
                cardData: vm.cardData!,
                template: vm.selectedTemplate,
                font: vm.selectedFont,
                backgroundImage: vm.backgroundImage,
                scrimOpacity: vm.scrimOpacity,
                useVignette: vm.useVignette,
                headlineScale: vm.headlineScale,
              ),
            ),
          ),
        ),

        // New PicsArt-style bottom tool dock
        PicsartToolDock(),
      ],
    );
  }
}
