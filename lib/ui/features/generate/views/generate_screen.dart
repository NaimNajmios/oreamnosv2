import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/config/theme/app_typography.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_outlined_button.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/core/widgets/app_copy_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/core/widgets/curated_post_sections.dart';
import 'package:oreamnos/ui/core/widgets/enhanced_loading_card.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/core/widgets/input_clear_button.dart';
import 'package:oreamnos/ui/core/widgets/link_preview_card.dart';
import 'package:oreamnos/ui/core/widgets/ocr_extraction_sheet.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/core/widgets/refinement_pill.dart';
import 'package:oreamnos/ui/core/widgets/section_header.dart';
import 'package:oreamnos/ui/core/widgets/source_attribution_card.dart';
import 'package:oreamnos/ui/core/widgets/success_overlay.dart';
import 'package:oreamnos/ui/core/widgets/swipeable_output_card.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/ui/features/settings/views/widgets/add_pill_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_models/generate_view_model.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _controller = TextEditingController();
  bool _showSuccessOverlay = false;
  bool _lastSuccessState = false;

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

  Future<void> _checkAndShowSuccessOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('hasShownSuccessOverlay') ?? false;
    if (!shown && mounted) {
      await prefs.setBool('hasShownSuccessOverlay', true);
      setState(() => _showSuccessOverlay = true);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      Haptics.lightImpact();
      setState(() {});
    }
  }

  void _handleClear() {
    final prevText = _controller.text;
    _controller.clear();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Input text cleared'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.success,
            onPressed: () {
              _controller.text = prevText;
              setState(() {});
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        ),
      );
    }
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
    final isSuccess = viewModel.state == GenerateState.success && viewModel.curatedPost != null;

    if (isSuccess && !_lastSuccessState) {
      _lastSuccessState = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowSuccessOverlay();
      });
    } else if (!isSuccess) {
      _lastSuccessState = false;
    }

    final validationMsg = viewModel.validationMessage ?? viewModel.errorMessage;
    final needsConfig = validationMsg != null && (validationMsg.toLowerCase().contains('api key') || validationMsg.toLowerCase().contains('model'));

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
      body: Stack(
        children: [
          SafeArea(
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
                      // Validation banner (pre-flight)
                      if (needsConfig && viewModel.state == GenerateState.error)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.base),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  validationMsg,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.w500),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Haptics.lightImpact();
                                  context.push(RoutePaths.settings);
                                },
                                child: const Text('Configure'),
                              ),
                            ],
                          ),
                        ),
                        // Capture Section (Hidden on Success)
                        if (!isSuccess)
                          _buildCaptureCard(context, viewModel, isUrl, hasContent, isGenerating),
                        
                        // Output Section (Hidden when Idle)
                        if (viewModel.state != GenerateState.idle) ...[
                          if (!isSuccess) ...[
                            const SizedBox(height: AppSpacing.xxl),
                            Divider(thickness: 1, height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55)),
                            const SizedBox(height: AppSpacing.base),
                            const SectionHeader(title: 'Output'),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: Column(
                              key: ValueKey(viewModel.state),
                              children: [
                                _buildResultArea(context, theme, viewModel, isSuccess),
                                if (isSuccess) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  AppOutlinedButton(
                                    label: 'New Entry',
                                    icon: Icons.add_rounded,
                                    onPressed: () {
                                      _handleClear();
                                      // Note: To clear curatedPost, we should clear pending inputs
                                      viewModel.reset();
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showSuccessOverlay)
            SuccessOverlay(
              onDismiss: () {
                if (mounted) setState(() => _showSuccessOverlay = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCaptureCard(
    BuildContext context,
    GenerateViewModel viewModel,
    bool isUrl,
    bool hasContent,
    bool isGenerating,
  ) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsViewModel>();
    final providerLabel = settings.selectedProvider.displayName;
    final modelLabel = settings.selectedModel ?? 'Auto';
    final toneLabel = settings.toneMode[0].toUpperCase() + settings.toneMode.substring(1);
    final charCount = _controller.text.length;
    final wordCount = _controller.text.trim().isEmpty ? 0 : _controller.text.trim().split(RegExp(r'\s+')).length;
    final isSuccess = viewModel.state == GenerateState.success && viewModel.curatedPost != null;

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
            LinkPreviewCard(
              url: _controller.text.trim(),
              isLoading: isGenerating,
              onExtract: isGenerating
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      viewModel.generatePost(_controller.text);
                    },
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    InkWell(
                      onTap: isGenerating
                          ? null
                          : () {
                              OcrExtractionSheet.show(
                                context,
                                onSourceSelected: (source) {
                                  viewModel.extractTextFromImage(source);
                                },
                              );
                            },
                      borderRadius: AppSpacing.borderRadiusPill,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          borderRadius: AppSpacing.borderRadiusPill,
                          border: Border.all(color: theme.colorScheme.outline, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (viewModel.isExtractingImage)
                              SizedBox(
                                child: KickoffLoadingIndicator(size: 14),
                              )
                            else
                              Icon(Icons.document_scanner_outlined, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text('Scan Image', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    ),
                    if (hasContent)
                      InputClearButton(
                        onClear: _handleClear,
                      )
                    else
                      InkWell(
                        onTap: isGenerating ? null : _pasteFromClipboard,
                        borderRadius: AppSpacing.borderRadiusPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: AppSpacing.borderRadiusPill,
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.content_paste_rounded, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text('Paste', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (hasContent) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: charCount > 8000 ? theme.colorScheme.error.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: AppSpacing.borderRadiusXs,
                    ),
                    child: Text(
                      '$wordCount words • $charCount chars',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: charCount > 8000 ? FontWeight.w700 : FontWeight.w500,
                        color: charCount > 8000 ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),

                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(thickness: 1, height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55)),
          const SizedBox(height: AppSpacing.sm),
          // Config footer — muted text, no scroll, no clipping
          InkWell(
            onTap: () {
              Haptics.lightImpact();
              context.push(RoutePaths.settings);
            },
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$providerLabel • $modelLabel • $toneLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          AppButton(
            label: isGenerating
                ? (viewModel.generatingStep == GeneratingStep.scraping ? 'Extracting URL...' : 'Curating Post...')
                : 'Generate Post',
            icon: Icons.auto_awesome_rounded,
            isLoading: isGenerating,
            onPressed: (!hasContent || isGenerating)
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    viewModel.generatePost(_controller.text);
                  },
          ),
          if (viewModel.recentInputs.isNotEmpty && !isGenerating && !isSuccess) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(thickness: 1, height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                dense: true,
                initiallyExpanded: false,
                title: Text('Recent', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                trailing: Icon(Icons.expand_more_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: viewModel.recentInputs.map((r) {
                        final truncated = r.length > 32 ? '${r.substring(0, 32)}…' : r;
                        return AppChip(
                          label: truncated,
                          onTap: () {
                            _controller.text = r;
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      final isScraping = viewModel.generatingStep == GeneratingStep.scraping;
      return EnhancedLoadingCard(
        key: const ValueKey('generating'),
        type: isScraping ? LoadingType.extracting : LoadingType.generating,
      );
    }

    if (viewModel.state == GenerateState.error) {
      return ErrorState(
        key: const ValueKey('error'),
        message: viewModel.errorMessage ?? 'An unexpected error occurred.',
        onRetry: () => viewModel.generatePost(_controller.text),
      );
    }

    if (viewModel.state == GenerateState.rateLimited) {
      return ErrorState(
        key: const ValueKey('rateLimited'),
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
      final post = viewModel.curatedPost!;
      final copyText = post.toMarkdownFiltered(showTitle: viewModel.showTitle, showHashtags: viewModel.showHashtags, showSource: false);
      return Column(
        key: const ValueKey('success'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwipeableOutputCard(
            content: copyText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          tooltip: 'Card Studio',
                          onPressed: () {
                            final settings = context.read<SettingsViewModel>();
                            if (settings.selectedModel != null) {
                              final brief = CardBrief.fromPost(
                                title: post.title,
                                bodyMarkdown: post.bodyMarkdown,
                                provider: settings.selectedProvider,
                                modelId: settings.selectedModel!,
                              );
                              context.push(RoutePaths.cardGenerator, extra: brief);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen_rounded, size: 22),
                          tooltip: 'Reading Mode',
                          onPressed: () {
                            context.push(
                              RoutePaths.readingMode,
                              extra: {'curatedPost': post},
                            );
                          },
                        ),
                        AppCopyButton(textToCopy: copyText),
                      ],
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.base),
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
                TitleBlock(title: post.title, visible: viewModel.showTitle),
                BodyBlock(bodyMarkdown: post.bodyMarkdown),
                if (viewModel.showHashtags && post.hashtags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  HashtagChips(hashtags: post.hashtags, visible: true),
                ],
                if (viewModel.showSource && !post.source.isEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  SourceAttributionCard(source: post.source),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (viewModel.canUndo)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    viewModel.undoLastRefinement();
                    Haptics.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Undid last refinement'), duration: const Duration(seconds: 2)));
                  },
                  borderRadius: AppSpacing.borderRadiusPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: AppSpacing.borderRadiusPill, border: Border.all(color: theme.colorScheme.outline)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.undo_rounded, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Undo', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                RefinementPill(
                  label: 'Rephrase',
                  icon: Icons.refresh_rounded,
                  onTap: () => viewModel.refineContent(
                    'Rephrase the report to be more formal and concise while keeping all facts and a neutral tone.',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RefinementPill(
                  label: 'Check Flow',
                  icon: Icons.auto_fix_high_rounded,
                  onTap: () => viewModel.refineContent(
                    'Improve the flow and clarity of the report without adding new facts.',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RefinementPill(
                  label: 'Shorter',
                  icon: Icons.compress_rounded,
                  onTap: () => viewModel.refineContent(
                    'Make the report shorter, 100-120 words, keeping a formal style.',
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

    // Idle — flat typographic, no gradient card
    return Container(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 22, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Curate Football Posts',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.85), letterSpacing: -0.2),
          ),
          const SizedBox(height: 4),
          Text(
            'Paste a URL, enter news, or scan an image to start.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Haptics.lightImpact();
                  _controller.text = 'Harimau Malaya secure dramatic 2-1 victory over rivals in Bukit Jalil with late winner from Faisal Halim.';
                  setState(() {});
                },
                child: const Text('Try sample news'),
              ),
              TextButton(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _controller.text = data!.text!;
                    setState(() {});
                  }
                },
                child: const Text('Paste URL'),
              ),
              TextButton(
                onPressed: () {
                  OcrExtractionSheet.show(context, onSourceSelected: (s) => viewModel.extractTextFromImage(s));
                },
                child: const Text('Scan Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _IdleExampleChip extends StatelessWidget {
  const _IdleExampleChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Haptics.lightImpact();
        onTap();
      },
      borderRadius: AppSpacing.borderRadiusPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(color: theme.colorScheme.outline, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
