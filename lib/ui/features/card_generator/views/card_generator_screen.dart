import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import '../view_models/card_generator_view_model.dart';
import '../widgets/card_canvas.dart';
import '../widgets/card_stage.dart';
import '../widgets/design_dock.dart';
import '../widgets/export_bottom_sheet.dart';
import '../widgets/inline_edit_bar.dart';

/// Sparse companion Card Studio — light visual to accompany caption.
class CardGeneratorScreen extends StatefulWidget {
  final CardBrief brief;
  final bool hasError;

  const CardGeneratorScreen({
    super.key,
    required this.brief,
    this.hasError = false,
  });

  @override
  State<CardGeneratorScreen> createState() => _CardGeneratorScreenState();
}

class _CardGeneratorScreenState extends State<CardGeneratorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.hasError || widget.brief.isEmpty) return;
      String apiKey = '';
      try {
        apiKey = await context.read<SettingsViewModel>().getApiKeyForProvider(widget.brief.provider) ?? '';
      } catch (_) {}
      if (!mounted) return;
      await context.read<CardGeneratorViewModel>().initialize(widget.brief, apiKey);
    });
  }

  Future<void> _handleSaveToGallery() async {
    final vm = context.read<CardGeneratorViewModel>();
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
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
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
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardGeneratorViewModel>();
    final theme = Theme.of(context);

    // Invalid entry (deep link / empty brief)
    if (widget.hasError || widget.brief.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Card Studio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3))),
        body: ErrorState(
          title: 'No card data',
          message: 'Generate a post first, then open Card Studio from the Generated Post card.',
          retryLabel: 'Back',
          onRetry: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final hasData = vm.cardData != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Card Studio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        actions: [
          if (hasData) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Card',
              onPressed: () => vm.shareCard(_boundaryKey),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
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
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
      body: _buildBody(context, vm, theme, hasData),
    );
  }

  Widget _buildBody(BuildContext context, CardGeneratorViewModel vm, ThemeData theme, bool hasData) {
    // Extracting skeleton — keep stage visible with seeded data if available
    if (vm.isExtracting && !hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Polishing card…', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('AI is tightening the headline for visual punch', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
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
            apiKey = await context.read<SettingsViewModel>().getApiKeyForProvider(widget.brief.provider) ?? '';
          } catch (_) {}
          vm.extractData(apiKey);
        },
      );
    }

    if (!hasData) {
      return const Center(child: Text('No data.'));
    }

    final isPolishing = vm.isExtracting;

    return Column(
      children: [
        // Stage + optional polishing banner
        Expanded(
          child: Stack(
            children: [
              CardStage(
                boundaryKey: _boundaryKey,
                aspectRatio: vm.selectedRatio.ratio,
                child: CardCanvas(
                  cardData: vm.cardData!,
                  template: vm.selectedTemplate,
                  font: vm.selectedFont,
                  backgroundImage: vm.backgroundImage,
                  scrimOpacity: vm.scrimOpacity,
                  useVignette: vm.useVignette,
                ),
              ),
              if (isPolishing)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.92),
                        borderRadius: AppSpacing.borderRadiusPill,
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                        boxShadow: AppSpacing.softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: theme.colorScheme.primary)),
                          const SizedBox(width: 8),
                          Text('Polishing…', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Inline edit — always visible when hasData
        InlineEditBar(viewModel: vm),

        // Dock — scrollable, stays below edit bar
        Flexible(
          child: SingleChildScrollView(
            child: DesignDock(viewModel: vm),
          ),
        ),
      ],
    );
  }
}
