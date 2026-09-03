import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/ui/core/dialogs/rate_limit_dialog.dart';
import 'package:oreamnos/ui/core/widgets/app_snackbar.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/config/theme/app_typography.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_outlined_button.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/core/widgets/app_copy_button.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';
import 'package:oreamnos/ui/core/widgets/curated_post_sections.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/core/widgets/fluid_edit_button.dart';
import 'package:oreamnos/ui/core/widgets/input_clear_button.dart';
import 'package:oreamnos/ui/features/generate/widgets/twitter_fallback_dialog.dart';
import 'package:oreamnos/ui/core/widgets/link_preview_card.dart';
import 'package:oreamnos/ui/core/widgets/refinement_pill.dart';
import 'package:oreamnos/ui/core/widgets/section_header.dart';
import 'package:oreamnos/ui/core/widgets/source_attribution_card.dart';
import 'package:oreamnos/ui/core/widgets/success_overlay.dart';
import 'package:oreamnos/ui/core/widgets/swipeable_output_card.dart';
import 'package:oreamnos/ui/core/widgets/enhanced_loading_card.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_mark.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/ui/features/settings/views/widgets/add_pill_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view_models/generate_view_model.dart';
import '../view_models/generate_state.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  final _controller = TextEditingController();
  bool _showSuccessOverlay = false;
  bool _lastSuccessState = false;
  bool _showSettings = false;

  // Link preview metadata (fetched lazily, dismissed per-URL).
  String _previewFor = '';
  String? _previewDismissedFor;
  String? _previewTitle;
  String? _previewDesc;
  String? _previewFavicon;

  void _maybeFetchPreview(String url, bool isGenerating) {
    if (isGenerating || url == _previewFor || url == _previewDismissedFor) {
      return;
    }
    _previewFor = url;
    WebScraperService.extractArticleFromUrl(url)
        .then((article) {
          if (!mounted) return;
          if (_controller.text.trim() != url) return;
          setState(() {
            _previewTitle = article.pageTitle;
            _previewDesc = article.description;
            _previewFavicon = article.faviconUrl;
          });
        })
        .catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    // Quick Settings tile flow (Android `GenerateTileService` parity): the
    // tile opens the app; on launch we pick up a URL sitting in the
    // clipboard into the empty input so one tap generates.
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeQsClipboard());
  }

  Future<void> _consumeQsClipboard() async {
    if (!mounted || _controller.text.trim().isNotEmpty) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty || !WebScraperService.isUrl(text)) return;
      if (!mounted || _controller.text.trim().isNotEmpty) return;
      setState(() => _controller.text = WebScraperService.normalizeUrl(text));
    } catch (_) {}
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

  /// Confirms discarding the current post + refinement history.
  Future<bool> _confirmDiscardPost(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new entry?'),
        content: const Text(
          'This discards the current post and its refinement history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleClear() {
    final prevText = _controller.text;
    _controller.clear();
    setState(() {});
    if (mounted) {
      AppSnackBar.show(
        context,
        'Input text cleared',
        actionLabel: 'UNDO',
        onAction: () => setState(() => _controller.text = prevText),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen<GenerateUiState>(generateViewModelProvider, (prev, next) {
      if (next.status == GenerateState.rateLimited &&
          next.suggestedFallbackProvider != null &&
          prev?.status != GenerateState.rateLimited) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final notifier = ref.read(generateViewModelProvider.notifier);
          RateLimitDialog.show(
            context,
            suggestedFallbackProvider: next.suggestedFallbackProvider,
            currentProviderName: notifier.providerDisplayName,
            onRetryWithFallback: () =>
                notifier.retryWithProvider(next.suggestedFallbackProvider!),
            waitTimeMessage: next.rateLimitWaitMessage,
          );
        });
      } else if (next.status == GenerateState.error &&
          next.twitterExtractionUrl != null &&
          prev?.status != GenerateState.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                TwitterFallbackDialog(originalUrl: next.twitterExtractionUrl!),
          ).then((pastedText) {
            if (pastedText != null && pastedText.isNotEmpty) {
              // Populate the UI with the pasted text and trigger generation
              _controller.text = pastedText;
              final notifier = ref.read(generateViewModelProvider.notifier);
              notifier.setPendingInput(pastedText);
              notifier.generatePost(pastedText);
            }
          });
        });
      }
    });
    final uiState = ref.watch(generateViewModelProvider);
    final notifier = ref.read(generateViewModelProvider.notifier);

    if (uiState.pendingInput != null &&
        uiState.pendingInput != _controller.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = uiState.pendingInput!;
        notifier.clearPendingInput();
      });
    }

    final isUrl = WebScraperService.isUrl(_controller.text.trim());
    final hasContent = _controller.text.trim().isNotEmpty;
    final isGenerating =
        uiState.status == GenerateState.generating ||
        uiState.status == GenerateState.researching;
    final hasPost = uiState.curatedPost != null;

    if (hasPost && !_lastSuccessState) {
      _lastSuccessState = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowSuccessOverlay();
      });
    } else if (!hasPost) {
      _lastSuccessState = false;
    }

    final validationMsg = uiState.validationMessage ?? uiState.errorMessage;
    final needsConfig =
        validationMsg != null &&
        (validationMsg.toLowerCase().contains('api key') ||
            validationMsg.toLowerCase().contains('model'));

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(child: KickoffAppBarMark(size: 28)),
        ),
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
              context.go(RoutePaths.usage);
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
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.base,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Validation banner (pre-flight)
                      if (needsConfig && uiState.status == GenerateState.error)
                        Container(
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.base,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  validationMsg,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                      // App Icon Decoration
                      if (!hasPost)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Center(
                            child:
                                SvgPicture.asset(
                                      'icon/icon_kickoff_transparent.svg',
                                      width: 72,
                                      height: 72,
                                      colorFilter: ColorFilter.mode(
                                        theme.colorScheme.primary,
                                        BlendMode.srcIn,
                                      ),
                                    )
                                    .animate(
                                      key: ValueKey(isGenerating),
                                      onPlay: (controller) {
                                        bool isTest = false;
                                        try {
                                          isTest = Platform.environment
                                              .containsKey('FLUTTER_TEST');
                                        } catch (_) {}
                                        if (!isTest && isGenerating) {
                                          controller.repeat();
                                        }
                                      },
                                    )
                                    .rotate(
                                      duration: const Duration(seconds: 4),
                                      curve: Curves.linear,
                                    ),
                          ),
                        ),

                      // Capture Section (Hidden on Success)
                      if (!hasPost)
                        _buildCaptureCard(
                          context,
                          uiState,
                          isUrl,
                          hasContent,
                          isGenerating,
                        ),

                      // Output Section (Hidden when Idle)
                      if (uiState.status != GenerateState.idle) ...[
                        if (!hasPost) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          Divider(
                            thickness: 1,
                            height: 1,
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          const SectionHeader(title: 'Output'),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: Column(
                            key: ValueKey(hasPost),
                            children: [
                              _buildResultArea(
                                context,
                                theme,
                                uiState,
                                hasPost,
                                isGenerating,
                              ),
                              if (hasPost) ...[
                                const SizedBox(height: AppSpacing.xl),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppOutlinedButton(
                                        label: 'New Entry',
                                        icon: Icons.add_rounded,
                                        onPressed: () async {
                                          final discard =
                                              await _confirmDiscardPost(
                                                context,
                                              );
                                          if (!discard || !context.mounted) {
                                            return;
                                          }
                                          _handleClear();
                                          notifier.reset();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: AppButton(
                                        label: 'Regenerate',
                                        icon: Icons.refresh_rounded,
                                        isLoading: isGenerating,
                                        onPressed: isGenerating
                                            ? null
                                            : () {
                                                notifier.generatePost(
                                                  _controller.text,
                                                );
                                              },
                                      ),
                                    ),
                                  ],
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
    GenerateUiState viewModel,
    bool isUrl,
    bool hasContent,
    bool isGenerating,
  ) {
    final theme = Theme.of(context);
    final state = ref.watch(settingsViewModelProvider);

    final providerLabel = state.selectedProvider.displayName;
    final modelLabel = state.selectedModel ?? 'Auto';
    final toneLabel =
        state.toneMode[0].toUpperCase() + state.toneMode.substring(1);
    final charCount = _controller.text.length;
    final wordCount = _controller.text.trim().isEmpty
        ? 0
        : _controller.text.trim().split(RegExp(r'\s+')).length;
    final hasPost = viewModel.curatedPost != null;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xs),
          AppInput(
            controller: _controller,
            hint: 'Paste football news or article URL...',
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {
              final trimmed = _controller.text.trim();
              if (trimmed != _previewFor) {
                _previewTitle = null;
                _previewDesc = null;
                _previewFavicon = null;
              }
            }),
          ),
          if (isUrl && _controller.text.trim() != _previewDismissedFor) ...[
            const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (context) {
                _maybeFetchPreview(_controller.text.trim(), isGenerating);
                return LinkPreviewCard(
                  url: _controller.text.trim(),
                  title: _previewTitle,
                  description: _previewDesc,
                  faviconUrl: _previewFavicon,
                  isLoading: isGenerating,
                  onExtract: isGenerating
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          ref
                              .read(generateViewModelProvider.notifier)
                              .generatePost(_controller.text);
                        },
                  onDismiss: () => setState(() {
                    _previewDismissedFor = _controller.text.trim();
                    _previewTitle = null;
                    _previewDesc = null;
                    _previewFavicon = null;
                  }),
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (hasContent)
                      InputClearButton(onClear: _handleClear)
                    else
                      AppChip(
                        label: 'Paste URL',
                        icon: Icons.content_paste_rounded,
                        onTap: isGenerating ? null : _pasteFromClipboard,
                        selected: false,
                      ),
                  ],
                ),
              ),
              if (hasContent) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: charCount > 8000
                          ? theme.colorScheme.error.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: AppSpacing.borderRadiusXs,
                    ),
                    child: Text(
                      '$wordCount words • $charCount chars',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: charCount > 8000
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: charCount > 8000
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            thickness: 1,
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: AppSpacing.md),

          // Advanced Settings Toggle
          InkWell(
            onTap: () {
              Haptics.lightImpact();
              setState(() => _showSettings = !_showSettings);
            },
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: 4,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_suggest_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Advanced Options',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showSettings
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<PromptLength>(
                    segments: const [
                      ButtonSegment(
                        value: PromptLength.short,
                        label: Text('Short'),
                      ),
                      ButtonSegment(
                        value: PromptLength.medium,
                        label: Text('Medium'),
                      ),
                      ButtonSegment(
                        value: PromptLength.long,
                        label: Text('Long'),
                      ),
                    ],
                    selected: {viewModel.promptLength},
                    onSelectionChanged: isGenerating
                        ? null
                        : (set) {
                            ref
                                .read(generateViewModelProvider.notifier)
                                .setPromptLength(set.first);
                          },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.travel_explore_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'AI Research Mode',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: AppSwitch(
                          value: viewModel.isResearchModeEnabled,
                          onChanged: isGenerating
                              ? null
                              : (_) => ref
                                    .read(generateViewModelProvider.notifier)
                                    .toggleResearchMode(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_align_left_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Keep Structure',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: AppSwitch(
                          value: viewModel.keepStructure,
                          onChanged: isGenerating
                              ? null
                              : (_) => ref
                                    .read(generateViewModelProvider.notifier)
                                    .toggleKeepStructure(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _showSettings
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 2),
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
                  Icon(
                    Icons.tune_rounded,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$providerLabel • $modelLabel • $toneLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.base),
          AppButton(
            label: isGenerating
                ? (viewModel.status == GenerateState.researching
                      ? 'Searching for match stats...'
                      : (viewModel.generatingStep == GeneratingStep.scraping
                            ? 'Extracting URL...'
                            : 'Curating Post...'))
                : 'Generate Post',
            icon: Icons.auto_awesome_rounded,
            isLoading: isGenerating,
            onPressed: (!hasContent || isGenerating)
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    ref
                        .read(generateViewModelProvider.notifier)
                        .generatePost(_controller.text);
                  },
          ),
          if (viewModel.recentInputs.isNotEmpty &&
              !isGenerating &&
              !hasPost) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Recent:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: viewModel.recentInputs.take(5).map((r) {
                        final truncated = r.length > 24
                            ? '${r.substring(0, 24)}…'
                            : r;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: AppChip(
                            label: truncated,
                            onTap: () {
                              _controller.text = r;
                              setState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultArea(
    BuildContext context,
    ThemeData theme,
    GenerateUiState viewModel,
    bool hasPost,
    bool isGenerating,
  ) {
    if (isGenerating && !hasPost) {
      final isScraping =
          viewModel.generatingStep == GeneratingStep.scraping ||
          viewModel.status == GenerateState.researching;
      return EnhancedLoadingCard(
        key: const ValueKey('generating'),
        type: isScraping ? LoadingType.extracting : LoadingType.generating,
      );
    }

    if (viewModel.status == GenerateState.error && !hasPost) {
      return ErrorState(
        key: const ValueKey('error'),
        message: viewModel.errorMessage ?? 'An unexpected error occurred.',
        onRetry: () => ref
            .read(generateViewModelProvider.notifier)
            .generatePost(_controller.text),
      );
    }

    if (viewModel.status == GenerateState.rateLimited && !hasPost) {
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
            ref
                .read(generateViewModelProvider.notifier)
                .retryWithProvider(viewModel.suggestedFallbackProvider!);
          } else {
            ref
                .read(generateViewModelProvider.notifier)
                .generatePost(_controller.text);
          }
        },
      );
    }

    if (hasPost) {
      final post = viewModel.curatedPost!;
      final copyText = post.toPlainTextFiltered(
        showTitle: viewModel.showTitle,
        showHashtags: viewModel.showHashtags,
        showSource: viewModel.showSource,
        appendSourceForCopy: true,
      );
      return Column(
        key: const ValueKey('success'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwipeableOutputCard(
            content: copyText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isGenerating) ...[
                  LinearProgressIndicator(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ] else if (viewModel.status == GenerateState.error ||
                    viewModel.status == GenerateState.rateLimited) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage ?? 'An error occurred.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        FluidEditButton(
                          isEditing: viewModel.isEditMode,
                          onToggle: () => ref
                              .read(generateViewModelProvider.notifier)
                              .toggleEditMode(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image_outlined, size: 20),
                          tooltip: 'Card Studio',
                          onPressed: () {
                            final settingsState = ref.read(
                              settingsViewModelProvider,
                            );
                            final cardModelId =
                                (settingsState.selectedModel?.isNotEmpty ??
                                    false)
                                ? settingsState.selectedModel!
                                : settingsState.selectedProvider.defaultModelId;
                            final brief = CardBrief.fromPost(
                              title: post.title,
                              bodyMarkdown: post.bodyMarkdown,
                              provider: settingsState.selectedProvider,
                              modelId: cardModelId,
                            );
                            context.push(
                              RoutePaths.cardGenerator,
                              extra: brief,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen_rounded, size: 22),
                          tooltip: 'Reading Mode',
                          onPressed: () {
                            context.push(
                              RoutePaths.readingMode,
                              extra: {
                                'curatedPost': post,
                                'copyText': copyText,
                              },
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
                        onTap: ref
                            .read(generateViewModelProvider.notifier)
                            .toggleTitle,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'Hashtags',
                        icon: viewModel.showHashtags
                            ? Icons.check_rounded
                            : null,
                        selected: viewModel.showHashtags,
                        onTap: ref
                            .read(generateViewModelProvider.notifier)
                            .toggleHashtags,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'Source',
                        icon: viewModel.showSource ? Icons.check_rounded : null,
                        selected: viewModel.showSource,
                        onTap: ref
                            .read(generateViewModelProvider.notifier)
                            .toggleSource,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                if (viewModel.isEditMode)
                  _PostEditor(
                    key: ValueKey(post.rawMarkdown),
                    title: post.title,
                    body: post.bodyMarkdown,
                    onSave: (title, body) => ref
                        .read(generateViewModelProvider.notifier)
                        .saveEditedPost(title: title, body: body),
                    onCancel: () => ref
                        .read(generateViewModelProvider.notifier)
                        .toggleEditMode(),
                  )
                else ...[
                  TitleBlock(title: post.title, visible: viewModel.showTitle),
                  BodyBlock(bodyMarkdown: post.bodyMarkdown),
                ],
                if (viewModel.showHashtags && post.hashtags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  HashtagChips(hashtags: post.hashtags, visible: true),
                ],
                if (viewModel.showSource && !post.source.isEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  SourceAttributionCard(source: post.source),
                ],
                if (viewModel.isResearchModeEnabled &&
                    viewModel.searchSources.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'AI Research Context',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: viewModel.searchSources.map((url) {
                      final domain = Uri.tryParse(url)?.host ?? url;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              domain,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
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
                    ref
                        .read(generateViewModelProvider.notifier)
                        .undoLastRefinement();
                    AppSnackBar.showUndone(context, 'Undid last refinement');
                  },
                  borderRadius: AppSpacing.borderRadiusPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.borderRadiusPill,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.undo_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Undo',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
                      isLoading: isGenerating,
                      onTap: () => ref
                          .read(generateViewModelProvider.notifier)
                          .refineContent(
                            'Rephrase the report to be more formal and concise while keeping all facts and a neutral tone.',
                          ),
                    )
                    .animate(delay: const Duration(milliseconds: 0))
                    .fadeIn(duration: const Duration(milliseconds: 180))
                    .slideX(
                      begin: -0.08,
                      duration: const Duration(milliseconds: 180),
                    ),
                const SizedBox(width: AppSpacing.sm),
                RefinementPill(
                      label: 'Check Flow',
                      icon: Icons.auto_fix_high_rounded,
                      isLoading: isGenerating,
                      onTap: () => ref
                          .read(generateViewModelProvider.notifier)
                          .refineContent(
                            'Improve the flow and clarity of the report without adding new facts.',
                          ),
                    )
                    .animate(delay: AppConstants.staggerDelay)
                    .fadeIn(duration: const Duration(milliseconds: 180))
                    .slideX(
                      begin: -0.08,
                      duration: const Duration(milliseconds: 180),
                    ),
                const SizedBox(width: AppSpacing.sm),
                RefinementPill(
                      label: 'Shorter',
                      icon: Icons.compress_rounded,
                      isLoading: isGenerating,
                      onTap: () => ref
                          .read(generateViewModelProvider.notifier)
                          .refineContent(
                            'Make the report shorter, 100-120 words, keeping a formal style.',
                          ),
                    )
                    .animate(delay: AppConstants.staggerDelay * 2)
                    .fadeIn(duration: const Duration(milliseconds: 180))
                    .slideX(
                      begin: -0.08,
                      duration: const Duration(milliseconds: 180),
                    ),
                ...ref
                    .watch(settingsViewModelProvider)
                    .customPills
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child:
                            RefinementPill(
                                  label: e.value.label,
                                  isLoading: isGenerating,
                                  onTap: () => ref
                                      .read(generateViewModelProvider.notifier)
                                      .refineContent(e.value.instruction),
                                  onLongPress: () {
                                    AddPillDialog.show(
                                      context,
                                      existingPill: e.value,
                                    );
                                  },
                                )
                                .animate(
                                  delay:
                                      AppConstants.staggerDelay * (3 + e.key),
                                )
                                .fadeIn(
                                  duration: const Duration(milliseconds: 180),
                                )
                                .slideX(
                                  begin: -0.08,
                                  duration: const Duration(milliseconds: 180),
                                ),
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child:
                      RefinementPill(
                            label: 'Add Custom Pill',
                            icon: Icons.add_rounded,
                            onTap: () => AddPillDialog.show(context),
                          )
                          .animate(delay: AppConstants.staggerDelay * 4)
                          .fadeIn(duration: const Duration(milliseconds: 180))
                          .slideX(
                            begin: -0.08,
                            duration: const Duration(milliseconds: 180),
                          ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Should not be reached because this method is only called when status != idle.
    return const SizedBox.shrink();
  }
}

/// Inline title/body editor shown when output edit mode is on.
class _PostEditor extends StatefulWidget {
  const _PostEditor({
    super.key,
    required this.title,
    required this.body,
    required this.onSave,
    required this.onCancel,
  });

  final String title;
  final String body;
  final void Function(String title, String body) onSave;
  final VoidCallback onCancel;

  @override
  State<_PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<_PostEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.title);
    _bodyCtrl = TextEditingController(text: widget.body);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          controller: _titleCtrl,
          label: 'Title',
          hint: 'Post headline',
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.md),
        AppInput(
          controller: _bodyCtrl,
          label: 'Body',
          hint: 'Post body',
          minLines: 6,
          maxLines: 12,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: 'Save',
              height: 44,
              onPressed: () =>
                  widget.onSave(_titleCtrl.text.trim(), _bodyCtrl.text.trim()),
            ),
          ],
        ),
      ],
    );
  }
}
