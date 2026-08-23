import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/core/widgets/app_copy_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/core/widgets/ocr_extraction_sheet.dart';
import 'package:oreamnos/ui/core/widgets/refinement_pill.dart';
import 'package:oreamnos/ui/core/widgets/skeleton_loader.dart';
import 'package:oreamnos/ui/core/widgets/swipeable_output_card.dart';
import 'package:oreamnos/ui/core/widgets/typewriter_markdown.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/ui/features/settings/views/widgets/add_pill_dialog.dart';
import '../view_models/generate_view_model.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      Haptics.lightImpact();
      setState(() {});
    }
  }

  void _clearInput() {
    _controller.clear();
    Haptics.lightImpact();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<GenerateViewModel>();

    if (viewModel.pendingInput != null && viewModel.pendingInput != _controller.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = viewModel.pendingInput!;
        viewModel.clearPendingInput();
      });
    }

    final isUrl = WebScraperService.isUrl(_controller.text.trim());
    final hasContent = _controller.text.trim().isNotEmpty;
    final isGenerating = viewModel.state == GenerateState.generating;
    final isSuccess = viewModel.state == GenerateState.success && viewModel.formattedContent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Oreamnos',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Usage & Analytics',
            onPressed: () {
              Haptics.lightImpact();
              context.push(RoutePaths.usage);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Input Card
                  _buildInputCard(context, viewModel, isUrl, hasContent, isGenerating),
                  const SizedBox(height: AppSpacing.base),

                  // Primary CTA Button
                  AppButton(
                    label: isGenerating ? 'Curating Post...' : 'Generate Post',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: isGenerating,
                    onPressed: (!hasContent || isGenerating)
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            viewModel.generatePost(_controller.text);
                          },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Result State Area
                  _buildResultArea(context, theme, viewModel, isSuccess),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(
    BuildContext context,
    GenerateViewModel viewModel,
    bool isUrl,
    bool hasContent,
    bool isGenerating,
  ) {
    final theme = Theme.of(context);
    final charCount = _controller.text.length;
    final wordCount = _controller.text.trim().isEmpty
        ? 0
        : _controller.text.trim().split(RegExp(r'\s+')).length;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            controller: _controller,
            hint: 'Paste football news or article URL...',
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
          ),
          if (isUrl) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: AppSpacing.borderRadiusPill,
                border: Border.all(color: theme.colorScheme.outline, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _controller.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: theme.colorScheme.primary,
                    onPressed: _clearInput,
                    tooltip: 'Clear URL',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Trailing action buttons (OCR + Paste / Clear)
              Row(
                children: [
                  IconButton(
                    icon: viewModel.isExtractingImage
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          )
                        : const Icon(Icons.document_scanner_outlined, size: 20),
                    tooltip: 'Extract from Image (OCR)',
                    onPressed: isGenerating
                        ? null
                        : () {
                            OcrExtractionSheet.show(
                              context,
                              onSourceSelected: (source) {
                                viewModel.extractTextFromImage(source);
                              },
                            );
                          },
                  ),
                  IconButton(
                    icon: Icon(
                      hasContent ? Icons.clear_rounded : Icons.content_paste_rounded,
                      size: 20,
                    ),
                    tooltip: hasContent ? 'Clear' : 'Paste from clipboard',
                    onPressed: isGenerating
                        ? null
                        : (hasContent ? _clearInput : _pasteFromClipboard),
                  ),
                ],
              ),
              // Character / Word count
              if (hasContent)
                Text(
                  '$wordCount words • $charCount chars',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea(
    BuildContext context,
    ThemeData theme,
    GenerateViewModel viewModel,
    bool isSuccess,
  ) {
    if (viewModel.state == GenerateState.generating) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            SkeletonLoader.outputCard(context),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Synthesizing post with AI...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (viewModel.state == GenerateState.error) {
      return ErrorState(
        message: viewModel.errorMessage ?? 'An unexpected error occurred.',
        onRetry: () => viewModel.generatePost(_controller.text),
      );
    }

    if (viewModel.state == GenerateState.rateLimited) {
      return ErrorState(
        title: 'Rate Limit Reached',
        message: viewModel.errorMessage ?? 'Provider quota limit reached.',
        icon: Icons.hourglass_empty_rounded,
        retryLabel: viewModel.suggestedFallbackProvider != null
            ? 'Retry with ${viewModel.suggestedFallbackProvider!.displayName}'
            : 'Retry',
        onRetry: () {
          if (viewModel.suggestedFallbackProvider != null) {
            viewModel.retryWithProvider(viewModel.suggestedFallbackProvider!);
          } else {
            viewModel.generatePost(_controller.text);
          }
        },
      );
    }

    if (isSuccess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwipeableOutputCard(
            content: viewModel.formattedContent ?? '',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generated Post',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_outlined, size: 20),
                          tooltip: 'Card Generator',
                          onPressed: () async {
                            final settings = context.read<SettingsViewModel>();
                            if (settings.selectedModel != null) {
                              final apiKey = await settings.getApiKeyForProvider(settings.selectedProvider);
                              if (!context.mounted) return;
                              context.push(
                                RoutePaths.cardGenerator,
                                extra: {
                                  'generatedText': viewModel.formattedContent ?? '',
                                  'provider': settings.selectedProvider,
                                  'apiKey': apiKey ?? '',
                                  'modelId': settings.selectedModel!,
                                },
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen_rounded, size: 22),
                          tooltip: 'Reading Mode',
                          onPressed: () {
                            context.push(
                              RoutePaths.readingMode,
                              extra: viewModel.formattedContent ?? '',
                            );
                          },
                        ),
                        AppCopyButton(textToCopy: viewModel.formattedContent ?? ''),
                      ],
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.base),

                // Display toggles
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppChip(
                        label: 'Title',
                        icon: viewModel.showTitle ? Icons.check_rounded : null,
                        selected: viewModel.showTitle,
                        onTap: viewModel.toggleTitle,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'Hashtags',
                        icon: viewModel.showHashtags ? Icons.check_rounded : null,
                        selected: viewModel.showHashtags,
                        onTap: viewModel.toggleHashtags,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'Source',
                        icon: viewModel.showSource ? Icons.check_rounded : null,
                        selected: viewModel.showSource,
                        onTap: viewModel.toggleSource,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                // Output post body
                TypewriterMarkdown(
                  data: viewModel.formattedContent ?? '',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Refinement pills section
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                RefinementPill(
                  label: 'Rephrase',
                  icon: Icons.refresh_rounded,
                  onTap: () => viewModel.refineContent(
                    'Rephrase the post to make it more engaging and slightly different, but keep the core message.',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RefinementPill(
                  label: 'Check Flow',
                  icon: Icons.auto_fix_high_rounded,
                  onTap: () => viewModel.refineContent(
                    'Improve the flow and readability of the post.',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RefinementPill(
                  label: 'Shorter',
                  icon: Icons.compress_rounded,
                  onTap: () => viewModel.refineContent(
                    'Make the post more concise and shorter.',
                  ),
                ),
                ...context.watch<SettingsViewModel>().customPills.map(
                      (pill) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: RefinementPill(
                          label: pill.label,
                          onTap: () => viewModel.refineContent(pill.instruction),
                          onLongPress: () {
                            AddPillDialog.show(context, existingPill: pill);
                          },
                        ),
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: RefinementPill(
                    label: 'Add Custom Pill',
                    icon: Icons.add_rounded,
                    onTap: () => AddPillDialog.show(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Idle Hero View
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Curate Football Posts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paste a URL, enter news, or scan an image to start.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
