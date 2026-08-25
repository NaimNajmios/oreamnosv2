import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/core/providers/settings_provider.dart';
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
  ConsumerState<CardGeneratorScreen> createState() => _CardGeneratorScreenState();
}

class _CardGeneratorScreenState extends ConsumerState<CardGeneratorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.hasError || widget.brief.isEmpty) return;
      String apiKey = '';
      try {
        // Prefer Riverpod settings, fallback to legacy
        apiKey = await ref.read(settingsProvider.notifier).getApiKeyForProvider(widget.brief.provider) ?? '';
        if (apiKey.isEmpty) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          apiKey = await legacy_provider.Provider.of<SettingsViewModel>(context, listen: false).getApiKeyForProvider(widget.brief.provider) ?? '';
        }
      } catch (_) {}
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      await legacy_provider.Provider.of<CardGeneratorViewModel>(context, listen: false).initialize(widget.brief, apiKey);
    });
  }

  Future<void> _handleSaveToGallery() async {
    final vm = legacy_provider.Provider.of<CardGeneratorViewModel>(context, listen: false);
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
    return legacy_provider.Consumer<CardGeneratorViewModel>(builder: (context, vm, _) {
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
    });
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
            apiKey = await legacy_provider.Provider.of<SettingsViewModel>(context, listen: false).getApiKeyForProvider(widget.brief.provider) ?? '';
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
        PicsartToolDock(viewModel: vm),
      ],
    );
  }
}
