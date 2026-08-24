import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import '../view_models/card_generator_view_model.dart';
import '../widgets/card_canvas.dart';
import '../widgets/export_bottom_sheet.dart';

/// 3-Zone Card Generator Screen for visual social media graphic production.
class CardGeneratorScreen extends StatefulWidget {
  final String generatedText;
  final AiProvider provider;
  final String apiKey;
  final String modelId;

  const CardGeneratorScreen({
    super.key,
    required this.generatedText,
    required this.provider,
    required this.apiKey,
    required this.modelId,
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
      String apiKey = widget.apiKey;
      if (apiKey.isEmpty) {
        try {
          final settings = context.read<SettingsViewModel>();
          apiKey = await settings.getApiKeyForProvider(widget.provider) ?? '';
        } catch (_) {}
      }
      if (!mounted) return;
      context.read<CardGeneratorViewModel>().extractData(
            widget.generatedText,
            widget.provider,
            apiKey,
            widget.modelId,
          );
    });
  }

  Future<void> _handleSaveToGallery() async {
    final viewModel = context.read<CardGeneratorViewModel>();
    final success = await viewModel.saveToGallery(_boundaryKey);
    if (mounted) {
      if (success) {
        Haptics.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Card saved to gallery successfully'),
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
                Text('Failed to save image to gallery'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CardGeneratorViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Card Generator',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (viewModel.cardData != null) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Card',
              onPressed: () => viewModel.shareCard(_boundaryKey),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export',
              onPressed: () {
                Haptics.lightImpact();
                ExportBottomSheet.show(
                  context,
                  onSaveToGallery: _handleSaveToGallery,
                  onShare: () => viewModel.shareCard(_boundaryKey),
                );
              },
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
      body: viewModel.isExtracting
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Extracting Highlights & Quotes...',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Formatting visual layout with AI',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : viewModel.extractionError != null
              ? ErrorState(
                  title: 'Extraction Failed',
                  message: viewModel.extractionError!,
                  retryLabel: 'Retry Extraction',
                  onRetry: () async {
                    String apiKey = widget.apiKey;
                    if (apiKey.isEmpty) {
                      try {
                        apiKey = await context.read<SettingsViewModel>().getApiKeyForProvider(widget.provider) ?? '';
                      } catch (_) {}
                    }
                    viewModel.extractData(
                      widget.generatedText,
                      widget.provider,
                      apiKey,
                      widget.modelId,
                    );
                  },
                )
              : viewModel.cardData != null
                  ? Column(
                      children: [
                        // Zone 2: Live Canvas Preview
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.base),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 380),
                                decoration: BoxDecoration(
                                  borderRadius: AppSpacing.borderRadiusMd,
                                  boxShadow: AppSpacing.elevatedShadow,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: RepaintBoundary(
                                  key: _boundaryKey,
                                  child: CardCanvas(
                                    cardData: viewModel.cardData!,
                                    template: viewModel.selectedTemplate,
                                    background: viewModel.selectedBackground,
                                    font: viewModel.selectedFont,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Zone 3: Bottom Design Studio Panel
                        _buildDesignPanel(context, viewModel),
                      ],
                    )
                  : const Center(child: Text('No data extracted.')),
    );
  }

  Widget _buildDesignPanel(BuildContext context, CardGeneratorViewModel viewModel) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Template Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Text(
                'TEMPLATE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Row(
                children: [
                  AppChip(
                    label: 'Standard',
                    selected: viewModel.selectedTemplate == CardTemplate.playerSpotlight,
                    onTap: () => viewModel.setTemplate(CardTemplate.playerSpotlight),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Quote',
                    selected: viewModel.selectedTemplate == CardTemplate.headlineQuote,
                    onTap: () => viewModel.setTemplate(CardTemplate.headlineQuote),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Breaking',
                    selected: viewModel.selectedTemplate == CardTemplate.breakingNews,
                    onTap: () => viewModel.setTemplate(CardTemplate.breakingNews),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Background Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Text(
                'BACKGROUND',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Row(
                children: CardBackground.values.map((bg) {
                  final isSelected = viewModel.selectedBackground == bg;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: AppChip(
                      label: bg.name.toUpperCase(),
                      selected: isSelected,
                      onTap: () => viewModel.setBackground(bg),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Typography Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Text(
                'TYPOGRAPHY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Row(
                children: [
                  AppChip(
                    label: 'Inter Sans',
                    selected: viewModel.selectedFont == AppFont.defaultFont,
                    onTap: () => viewModel.setFont(AppFont.defaultFont),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Lora Serif',
                    selected: viewModel.selectedFont == AppFont.classicSerif,
                    onTap: () => viewModel.setFont(AppFont.classicSerif),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Space Mono',
                    selected: viewModel.selectedFont == AppFont.typewriter,
                    onTap: () => viewModel.setFont(AppFont.typewriter),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
