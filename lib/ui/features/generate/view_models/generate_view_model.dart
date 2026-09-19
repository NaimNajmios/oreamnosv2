import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/repositories/content_repository.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/notification_service.dart';
import 'package:oreamnos/data/services/token_usage_side_channel.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/domain/repositories/search_repository.dart';
import 'package:oreamnos/domain/services/enrich_context_usecase.dart';
import 'package:oreamnos/domain/services/intent_classifier.dart';
import 'package:oreamnos/data/services/twitter_extractor.dart';
import 'package:oreamnos/data/services/twitter_article_enricher.dart';
import 'package:oreamnos/core/utils/shared_content_parser.dart';
import 'package:oreamnos/core/utils/url_detector.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/vision_curator_chain.dart';
import 'package:oreamnos/data/services/vision_image_prep.dart';
import 'package:oreamnos/domain/models/vision_mode.dart';
import 'package:oreamnos/domain/services/vision_extractor.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'generate_state.dart';

enum GenerateState {
  idle,
  researching,
  generating,
  success,
  error,
  rateLimited,
}

enum GeneratingStep { idle, scraping, prompting }

class ValidationResult {
  final bool isValid;
  final String? message;
  const ValidationResult.valid() : isValid = true, message = null;
  const ValidationResult.invalid(this.message) : isValid = false;
}

final generateViewModelProvider =
    NotifierProvider<GenerateViewModel, GenerateUiState>(GenerateViewModel.new);

enum PromptLength { short, medium, long }

class GenerateViewModel extends Notifier<GenerateUiState>
    with WidgetsBindingObserver {
  late final UsageService _usageService;
  bool _isBackgrounded = false;
  int _generationSessionId = 0;

  @override
  GenerateUiState build() {
    _usageService = getIt<UsageService>();
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });

    if (getIt.isRegistered<PreferencesService>()) {
      final prefs = getIt<PreferencesService>();
      if (prefs.persistGenerationOptions) {
        final length = PromptLength.values.firstWhere(
          (e) => e.name == prefs.lastPromptLength,
          orElse: () => PromptLength.medium,
        );
        return GenerateUiState(
          promptLength: length,
          isResearchModeEnabled: prefs.lastIsResearchMode,
          keepStructure: prefs.lastKeepStructure,
        );
      }
    }

    return const GenerateUiState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackgrounded =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
  }

  // Compatibility getters — proxy to Notifier state for callers using notifier
  GenerateState get status => state.status;
  // ignore: avoid_renaming_method_parameters
  GenerateState get generateState => state.status;
  GeneratingStep get generatingStep => state.generatingStep;
  CuratedPost? get curatedPost => state.curatedPost;
  String? get generatedContent => state.curatedPost?.rawMarkdown;
  bool get canUndo => state.canUndo;
  List<String> get recentInputs => state.recentInputs;
  String? get errorMessage => state.errorMessage;
  AiProvider? get suggestedFallbackProvider => state.suggestedFallbackProvider;
  String? get validationMessage => state.validationMessage;
  String? get twitterExtractionUrl => state.twitterExtractionUrl;
  String? get pendingInput => state.pendingInput;
  bool get isResearchModeEnabled => state.isResearchModeEnabled;
  List<String> get searchSources => state.searchSources;
  bool get showTitle => state.showTitle;
  bool get showHashtags => state.showHashtags;
  bool get showSource => state.showSource;
  PromptLength get promptLength => state.promptLength;
  bool get isExtractingImage => state.isExtractingImage;

  String? get formattedContent {
    final cp = state.curatedPost;
    if (cp == null) return null;
    return cp.toPlainTextFiltered(
      showTitle: state.showTitle,
      showHashtags: state.showHashtags,
      showSource: state.showSource,
    );
  }

  String? get formattedBody => state.curatedPost?.bodyMarkdown;
  SourceAttribution? get sourceAttribution => state.curatedPost?.source;

  String get _lengthInstruction {
    switch (state.promptLength) {
      case PromptLength.short:
        return 'Short and Direct. You MUST include ALL facts and meaning from the original content, but strip away all filler words. Be extremely direct and concise. DO NOT omit any key details or names.';
      case PromptLength.medium:
        return 'Medium and Natural. Translate and rewrite the original content naturally so it is easy to digest. Avoid stiff, literal translation phrasing, but ensure 100% of the original meaning is retained.';
      case PromptLength.long:
        return 'Long and Comprehensive. Extract EVERY available detail, minor fact, statistic, and quote from the source material to write a full-length, detailed article. DO NOT invent facts, DO NOT use external knowledge, and DO NOT add personal commentary, assumptions, or meaningless filler. The length must come ONLY from a deep, thorough extraction of the provided source.';
    }
  }

  void setPromptLength(PromptLength length) {
    state = state.copyWith(promptLength: length);
    if (getIt.isRegistered<PreferencesService>()) {
      final prefs = getIt<PreferencesService>();
      if (prefs.persistGenerationOptions) {
        prefs.setLastPromptLength(length.name);
      }
    }
  }

  AiProvider _getNextProvider(AiProvider current) => current.nextFallback;

  Future<void> retryWithProvider(AiProvider provider) async {
    final settingsNotifier = ref.read(settingsViewModelProvider.notifier);
    await settingsNotifier.setSelectedProvider(provider);
    // Ensure the fallback has a usable model: persist the provider default
    // when the user never picked one explicitly for this provider.
    final selectedModel = ref.read(settingsViewModelProvider).selectedModel;
    if ((selectedModel == null || selectedModel.isEmpty) &&
        provider.defaultModelId.isNotEmpty) {
      await settingsNotifier.setSelectedModel(provider.defaultModelId);
    }
    // Don't fire a doomed request when the fallback has no API key —
    // surface a named error so the user can configure it instead.
    final apiKey = await settingsNotifier.getApiKeyForProvider(provider);
    if (apiKey == null || apiKey.isEmpty) {
      final message =
          'API key not configured for ${provider.displayName}. Go to Settings → API Key.';
      state = state.copyWith(
        errorMessage: message,
        validationMessage: message,
        suggestedFallbackProvider: null,
        rateLimitWaitMessage: null,
        status: GenerateState.error,
      );
      return;
    }
    final pi = state.pendingInput;
    if (pi != null) {
      await generatePost(pi);
    }
  }

  void toggleResearchMode() {
    final next = !state.isResearchModeEnabled;
    state = state.copyWith(isResearchModeEnabled: next);
    if (getIt.isRegistered<PreferencesService>()) {
      final prefs = getIt<PreferencesService>();
      if (prefs.persistGenerationOptions) {
        prefs.setLastIsResearchMode(next);
      }
    }
  }

  void toggleTitle() {
    state = state.copyWith(showTitle: !state.showTitle);
  }

  void toggleKeepStructure() {
    final next = !state.keepStructure;
    state = state.copyWith(keepStructure: next);
    if (getIt.isRegistered<PreferencesService>()) {
      final prefs = getIt<PreferencesService>();
      if (prefs.persistGenerationOptions) {
        prefs.setLastKeepStructure(next);
      }
    }
  }

  void toggleHashtags() {
    state = state.copyWith(showHashtags: !state.showHashtags);
  }

  void toggleSource() {
    state = state.copyWith(showSource: !state.showSource);
  }

  /// Output edit mode (Android `isEditMode` / `FluidEditButton` parity).
  void toggleEditMode() {
    state = state.copyWith(isEditMode: !state.isEditMode);
  }

  /// Persists hand-edited title/body into the current post (undoable).
  void saveEditedPost({String? title, String? body}) {
    final cp = state.curatedPost;
    if (cp == null) return;
    _pushHistory(cp);
    state = state.copyWith(
      curatedPost: cp.copyWith(title: title, bodyMarkdown: body),
      isEditMode: false,
    );
  }

  ValidationResult validateForGenerate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult.invalid('Please enter news text or a URL.');
    }
    if (trimmed.length > 8000) {
      return const ValidationResult.invalid(
        'Input too long (max 8000 characters). Please shorten or paste a URL.',
      );
    }
    // Offline fallback: provider default model id (Android ModelRegistry parity).
    final settings = ref.read(settingsViewModelProvider);
    final modelId = settings.selectedModel;
    if ((modelId == null || modelId.isEmpty) &&
        settings.selectedProvider.defaultModelId.isEmpty) {
      return ValidationResult.invalid(
        'No model selected for $providerDisplayName. Go to Settings → Model.',
      );
    }
    return const ValidationResult.valid();
  }

  String get providerDisplayName =>
      ref.read(settingsViewModelProvider).selectedProvider.displayName;

  Future<ValidationResult> validateApiKey() async {
    final provider = ref.read(settingsViewModelProvider).selectedProvider;
    final apiKey = await ref
        .read(settingsViewModelProvider.notifier)
        .getApiKeyForProvider(provider);
    if (apiKey == null || apiKey.isEmpty) {
      return ValidationResult.invalid(
        'API key not configured for ${provider.displayName}. Go to Settings → API Key.',
      );
    }
    return const ValidationResult.valid();
  }

  void _pushHistory(CuratedPost content) {
    final list = List<String>.from(state.historyStack)
      ..add(jsonEncode(content.toJson()));
    if (list.length > 20) list.removeAt(0);
    state = state.copyWith(historyStack: list);
  }

  bool undoLastRefinement() {
    final stack = List<String>.from(state.historyStack);
    if (stack.isEmpty) return false;
    final jsonStr = stack.removeLast();
    CuratedPost? restored;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      restored = CuratedPost.fromJson(map);
    } catch (_) {
      restored = CuratedPost.fromMarkdownFallback(jsonStr);
    }
    state = state.copyWith(
      historyStack: stack,
      curatedPost: restored,
      status: GenerateState.success,
    );
    return true;
  }

  void _addRecentInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    final list = List<String>.from(state.recentInputs);
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 5) list.removeLast();
    state = state.copyWith(recentInputs: list);
  }

  void setPendingInput(String input) {
    state = state.copyWith(pendingInput: input);
  }

  void clearPendingInput() {
    state = state.copyWith(pendingInput: null);
  }

  Future<void> generatePost(String input) async {
    final sessionId = ++_generationSessionId;
    final v = validateForGenerate(input);
    if (!v.isValid) {
      if (sessionId != _generationSessionId) return;
      state = state.copyWith(
        errorMessage: v.message,
        validationMessage: v.message,
        status: GenerateState.error,
      );
      return;
    }
    final apiCheck = await validateApiKey();
    if (sessionId != _generationSessionId) return;
    if (!apiCheck.isValid) {
      state = state.copyWith(
        errorMessage: apiCheck.message,
        validationMessage: apiCheck.message,
        status: GenerateState.error,
      );
      return;
    }

    final trimmedInput = input.trim();
    _addRecentInput(trimmedInput);
    state = state.copyWith(
      status: GenerateState.generating,
      generatingStep: GeneratingStep.prompting,
      errorMessage: null,
      validationMessage: null,
      suggestedFallbackProvider: null,
      rateLimitWaitMessage: null,
      twitterExtractionUrl: null,
      pendingInput: trimmedInput,
    );

    final stopwatch = Stopwatch()..start();
    final provider = ref.read(settingsViewModelProvider).selectedProvider;

    try {
      final parsed = SharedContentParser.parse(trimmedInput);
      dynamic contentToCurate = trimmedInput;
      String? sourceUrl;
      String? siteName;
      String? authorDisplayName;
      String? candidateOutlet;
      bool isTwitter = false;

      // 1. Content Extraction Pipeline
      final isTwitterLink =
          parsed.urlType == UrlType.twitterStatus ||
          (parsed.primaryUrl != null &&
              TwitterExtractor.isTwitterUrl(parsed.primaryUrl!));

      if (isTwitterLink) {
        final targetTwitterUrl = parsed.primaryUrl ?? trimmedInput;
        state = state.copyWith(generatingStep: GeneratingStep.scraping);

        sourceUrl = targetTwitterUrl;
        isTwitter = true;

        TweetContent? tweet = await TwitterExtractor.extractViaFxTwitter(
          targetTwitterUrl,
        );

        if (tweet == null || !tweet.isValid) {
          tweet = await TwitterExtractor.extractViaVxTwitter(targetTwitterUrl);
        }

        if (tweet != null && tweet.isValid) {
          authorDisplayName = tweet.authorDisplayName;
          candidateOutlet = tweet.resolvedCandidateOutlet;

          final enricher = getIt.isRegistered<TwitterArticleEnricher>()
              ? getIt<TwitterArticleEnricher>()
              : TwitterArticleEnricher();
          final enrichment = await enricher.enrichFromTweet(
            tweet.text,
            cardUrl: tweet.cardUrl,
            expandedUrls: tweet.expandedUrls,
          );

          var promptBody = TwitterExtractor.formatForAiPrompt(
            tweet,
            linkedArticleContent: enrichment?.content,
            linkedArticleUrl: enrichment?.url,
          );
          if (parsed.accompanyingText.isNotEmpty) {
            promptBody =
                '$promptBody\n\nUSER COMMENTARY / CONTEXT:\n${parsed.accompanyingText}';
          }
          contentToCurate = promptBody;
        } else {
          // Fallback: If external APIs fail but user shared accompanying text, use it!
          if (parsed.accompanyingText.isNotEmpty) {
            contentToCurate = parsed.accompanyingText;
          } else {
            try {
              final searchRepo = getIt<ISearchRepository>();
              if (await searchRepo.isConfigured()) {
                contentToCurate = await searchRepo.extractFromUrl(
                  targetTwitterUrl,
                );
              } else {
                throw TwitterExtractionException(sourceUrl);
              }
            } catch (e) {
              throw TwitterExtractionException(sourceUrl);
            }
          }
        }

        state = state.copyWith(generatingStep: GeneratingStep.prompting);
      } else if (parsed.primaryUrl != null ||
          WebScraperService.isUrl(trimmedInput)) {
        final targetUrl = parsed.primaryUrl ?? trimmedInput;
        state = state.copyWith(generatingStep: GeneratingStep.scraping);
        try {
          final article = await WebScraperService.extractArticleFromUrl(
            targetUrl,
          ).timeout(const Duration(seconds: 10));
          contentToCurate = article;
          sourceUrl = article.url;
          siteName = article.siteName;
          if (article.text.trim().isEmpty || article.text.trim() == targetUrl) {
            getIt<LogService>().warning(
              'Scrape returned empty/fallback, using input text',
            );
            contentToCurate = parsed.accompanyingText.isNotEmpty
                ? parsed.accompanyingText
                : trimmedInput;
            sourceUrl = targetUrl;
          } else if (parsed.accompanyingText.isNotEmpty) {
            contentToCurate = ExtractedArticle(
              text:
                  'USER CONTEXT / HEADLINE:\n${parsed.accompanyingText}\n\nARTICLE BODY:\n${article.text}',
              url: article.url,
              domain: article.domain,
              pageTitle: article.pageTitle ?? parsed.accompanyingText,
              description: article.description,
              faviconUrl: article.faviconUrl,
              siteName: article.siteName,
            );
          }
        } on TimeoutException {
          if (parsed.accompanyingText.isNotEmpty) {
            contentToCurate = parsed.accompanyingText;
            sourceUrl = targetUrl;
          } else {
            throw Exception(
              'URL extraction timed out. Please paste the article text manually.',
            );
          }
        }
        state = state.copyWith(generatingStep: GeneratingStep.prompting);
      }

      // 2. AI Research Mode Enrichment (if enabled)
      if (state.isResearchModeEnabled) {
        state = state.copyWith(status: GenerateState.researching);

        final enrichUsecase = getIt<EnrichContextUseCase>();
        final textForEnrichment = contentToCurate is ExtractedArticle
            ? contentToCurate.text
            : contentToCurate.toString();

        final intent = IntentClassifier.classify(textForEnrichment);
        final enrichmentResult = await enrichUsecase.execute(
          textForEnrichment,
          intent,
        );

        if (contentToCurate is ExtractedArticle) {
          contentToCurate = contentToCurate.copyWith(
            text: enrichmentResult.content,
          );
        } else {
          contentToCurate = enrichmentResult.content;
        }

        final sources = enrichmentResult.sources;
        if (sourceUrl == null &&
            intent == InputIntent.url &&
            sources.isNotEmpty) {
          sourceUrl = sources.first;
        }

        state = state.copyWith(
          searchSources: sources,
          status: GenerateState.generating,
          generatingStep: GeneratingStep.prompting,
        );
      } else {
        state = state.copyWith(searchSources: []);
      }

      final settings = ref.read(settingsViewModelProvider);
      final modelId = (settings.selectedModel?.isNotEmpty ?? false)
          ? settings.selectedModel!
          : provider.defaultModelId;

      final apiKey = await ref
          .read(settingsViewModelProvider.notifier)
          .getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured for ${provider.displayName}.');
      }

      if (!state.keepStructure) {
        if (contentToCurate is ExtractedArticle) {
          final article = contentToCurate;
          contentToCurate = ExtractedArticle(
            text: '${article.text}\n\nLENGTH REQUIREMENT: $_lengthInstruction',
            url: article.url,
            domain: article.domain,
            pageTitle: article.pageTitle,
            description: article.description,
            faviconUrl: article.faviconUrl,
            siteName: article.siteName,
          );
        } else {
          contentToCurate =
              '$contentToCurate\n\nLENGTH REQUIREMENT: $_lengthInstruction';
        }
      }
      // API resilience: via pooled IContentRepository + Result fold + 30s timeout
      final repo = ref.read(contentRepositoryProvider);

      final repoResult = await repo
          .generateStructuredPost(
            content: contentToCurate,
            modelId: modelId,
            apiKey: apiKey,
            sourceUrl: sourceUrl,
            provider: provider,
            searchSources: state.searchSources,
            keepStructure: state.keepStructure,
            isFanModeEnabled: settings.isFanModeEnabled,
            fanClubName: settings.fanClubName,
            length: state.promptLength.name,
            siteName: siteName,
            authorDisplayName: authorDisplayName,
            candidateOutlet: candidateOutlet,
            isTwitter: isTwitter,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw const NetworkFailure('Request timed out after 30s'),
          );

      if (sessionId != _generationSessionId) return;

      // Handle Result via typed Failure — no string contains
      if (repoResult is ResultError<CuratedPost>) {
        final failure = repoResult.failure;
        stopwatch.stop();
        _usageService.logUsage(
          UsageLog(
            id: const Uuid().v4(),
            timestamp: DateTime.now(),
            providerId: provider.name,
            modelName: modelId,
            latencyMs: stopwatch.elapsedMilliseconds,
            estimatedTokens: 0,
            isSuccess: false,
          ),
        );
        getIt<LogService>().error('Failed to generate post', failure, null);
        if (failure is RateLimitFailure) {
          state = state.copyWith(
            errorMessage:
                'Rate limit exceeded for ${provider.displayName}. Try another provider. ${failure.waitTimeMessage}',
            suggestedFallbackProvider: _getNextProvider(provider),
            rateLimitWaitMessage: failure.waitTimeMessage,
            status: GenerateState.rateLimited,
            generatingStep: GeneratingStep.idle,
          );
        } else if (failure is PaymentRequiredFailure) {
          state = state.copyWith(
            errorMessage:
                'Credits exhausted for ${provider.displayName} (HTTP 402). Switch to another provider.',
            suggestedFallbackProvider: _getNextProvider(provider),
            status: GenerateState.rateLimited,
            generatingStep: GeneratingStep.idle,
          );
        } else if (failure is AuthFailure) {
          state = state.copyWith(
            errorMessage:
                'Authentication failed for ${provider.displayName}. Check your API key in Settings.',
            status: GenerateState.error,
            generatingStep: GeneratingStep.idle,
          );
        } else if (failure is NetworkFailure) {
          state = state.copyWith(
            errorMessage:
                'Network error. Please check your connection and try again.',
            status: GenerateState.error,
            generatingStep: GeneratingStep.idle,
          );
        } else {
          final msg = failure.message.length > 220
              ? '${failure.message.substring(0, 220)}...'
              : failure.message;
          state = state.copyWith(
            errorMessage: msg,
            status: GenerateState.error,
            generatingStep: GeneratingStep.idle,
          );
        }
        if (_isBackgrounded) {
          NotificationService().showGenerationCompleteNotification(
            'Generation Failed',
            'There was an error generating your post.',
          );
        }
        return;
      }

      var curated = (repoResult as ResultSuccess<CuratedPost>).data;

      if (ref.read(settingsViewModelProvider).defaultHashtags.isNotEmpty) {
        final tags = ref
            .read(settingsViewModelProvider)
            .defaultHashtags
            .split(RegExp(r'\s+'))
            .map((e) => e.replaceAll('#', '').trim())
            .where((e) => e.isNotEmpty)
            .toList();
        curated = curated.copyWith(hashtags: tags);
      }

      stopwatch.stop();
      int estimatedTokens = ((input.length + (curated.rawMarkdown.length)) / 4)
          .round();
      // Side-channel: use real total_tokens if captured
      try {
        if (getIt.isRegistered<TokenUsageSideChannel>()) {
          final side = getIt<TokenUsageSideChannel>();
          final real = side.consumeTotal();
          if (real != null && real > 0) estimatedTokens = real;
        }
      } catch (_) {}
      _usageService.logUsage(
        UsageLog(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: modelId,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: estimatedTokens,
          isSuccess: true,
        ),
      );

      getIt<LogService>().info(
        'Generated post successfully in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (sessionId != _generationSessionId) return;

      state = state.copyWith(
        curatedPost: curated,
        status: GenerateState.success,
        generatingStep: GeneratingStep.idle,
      );

      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Post Ready',
          'Your AI-curated social media post has been generated successfully.',
        );
      }
    } catch (e, st) {
      if (sessionId != _generationSessionId) return;
      // Only for non-API failures (Twitter, scrape, timeout before repo call)
      stopwatch.stop();
      _usageService.logUsage(
        UsageLog(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: ref.read(settingsViewModelProvider).selectedModel,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: 0,
          isSuccess: false,
        ),
      );

      getIt<LogService>().error('Failed to generate post', e, st);

      if (e is TwitterExtractionException) {
        state = state.copyWith(
          status: GenerateState.error,
          twitterExtractionUrl: e.url,
          errorMessage:
              'Could not extract tweet content from X. '
              'Please copy the tweet text directly and paste it here.\n\n'
              'Tip: Tap "..." on the tweet → "Copy text"',
          generatingStep: GeneratingStep.idle,
        );
      } else {
        final raw = e.toString();
        final clean = raw.startsWith('Exception:')
            ? raw.substring(10).trim()
            : raw;
        final msg = clean.length > 220
            ? '${clean.substring(0, 220)}...'
            : clean;
        state = state.copyWith(
          errorMessage: msg,
          status: GenerateState.error,
          generatingStep: GeneratingStep.idle,
        );
      }

      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Generation Failed',
          'There was an error generating your post.',
        );
      }
    }
  }

  void togglePillSelection(String pillId) {
    final current = Set<String>.from(state.selectedPillIds);
    if (current.contains(pillId)) {
      current.remove(pillId);
    } else {
      current.add(pillId);
    }
    state = state.copyWith(selectedPillIds: current);
  }

  void clearPillSelection() {
    state = state.copyWith(selectedPillIds: const {});
  }

  Future<void> refineContent(List<String> instructions) async {
    final cp = state.curatedPost;
    if (cp == null || instructions.isEmpty) return;

    final sessionId = ++_generationSessionId;

    _pushHistory(cp);
    state = state.copyWith(
      status: GenerateState.generating,
      generatingStep: GeneratingStep.prompting,
      errorMessage: null,
      validationMessage: null,
    );

    final stopwatch = Stopwatch()..start();
    final provider = ref.read(settingsViewModelProvider).selectedProvider;

    try {
      final settings = ref.read(settingsViewModelProvider);
      final modelId = (settings.selectedModel?.isNotEmpty ?? false)
          ? settings.selectedModel!
          : provider.defaultModelId;

      final apiKey = await ref
          .read(settingsViewModelProvider.notifier)
          .getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured for ${provider.displayName}.');
      }

      // Full refinement pipeline: instructions routed through
      // GenerationPromptManager.buildRefinementPrompt (rephrase /
      // recheck_flow / recheck_wording keys + free-text custom pills).
      final repo = ref.read(contentRepositoryProvider);

      final repoResult = await repo
          .refinePost(
            original: cp,
            refinements: instructions,
            modelId: modelId,
            apiKey: apiKey,
            provider: provider,
            includeSource: state.showSource,
            keepStructure: state.keepStructure,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw const NetworkFailure('Request timed out after 30s'),
          );

      if (sessionId != _generationSessionId) return;

      if (repoResult is ResultError<CuratedPost>) {
        throw repoResult.failure;
      }
      final refined = (repoResult as ResultSuccess<CuratedPost>).data;

      var merged = CuratedPost(
        title: refined.title.isEmpty ? cp.title : refined.title,
        bodyMarkdown: refined.bodyMarkdown.isEmpty
            ? cp.bodyMarkdown
            : refined.bodyMarkdown,
        hashtags: refined.hashtags.isEmpty ? cp.hashtags : refined.hashtags,
        source: cp.source,
        rawMarkdown: '',
      );
      merged = CuratedPost.fromJson({
        'title': merged.title,
        'body': merged.bodyMarkdown,
        'hashtags': merged.hashtags,
        'source': merged.source.toJson(),
      });

      stopwatch.stop();
      final combinedLength = instructions.fold<int>(
        0,
        (sum, i) => sum + i.length,
      );
      int estimatedTokens =
          ((combinedLength +
                      cp.rawMarkdown.length +
                      (merged.rawMarkdown.length)) /
                  4)
              .round();
      try {
        if (getIt.isRegistered<TokenUsageSideChannel>()) {
          final real = getIt<TokenUsageSideChannel>().consumeTotal();
          if (real != null && real > 0) estimatedTokens = real;
        }
      } catch (_) {}
      _usageService.logUsage(
        UsageLog(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: modelId,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: estimatedTokens,
          isSuccess: true,
        ),
      );

      getIt<LogService>().info(
        'Refined post successfully in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (sessionId != _generationSessionId) return;

      state = state.copyWith(
        curatedPost: merged,
        status: GenerateState.success,
        generatingStep: GeneratingStep.idle,
        selectedPillIds: const {},
      );

      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Refinement Ready',
          'Your refined social media post is ready.',
        );
      }
    } catch (e, st) {
      if (sessionId != _generationSessionId) return;
      stopwatch.stop();
      _usageService.logUsage(
        UsageLog(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: ref.read(settingsViewModelProvider).selectedModel,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: 0,
          isSuccess: false,
        ),
      );

      getIt<LogService>().error('Failed to refine post', e, st);

      if (e is RateLimitFailure) {
        state = state.copyWith(
          errorMessage:
              'Rate limit exceeded for ${provider.displayName}. ${e.waitTimeMessage}',
          suggestedFallbackProvider: _getNextProvider(provider),
          rateLimitWaitMessage: e.waitTimeMessage,
          status: GenerateState.rateLimited,
          generatingStep: GeneratingStep.idle,
        );
      } else if (e is PaymentRequiredFailure) {
        state = state.copyWith(
          errorMessage:
              'Credits exhausted for ${provider.displayName} (HTTP 402). Switch to another provider.',
          suggestedFallbackProvider: _getNextProvider(provider),
          status: GenerateState.rateLimited,
          generatingStep: GeneratingStep.idle,
        );
      } else if (e is AuthFailure) {
        state = state.copyWith(
          errorMessage:
              'Authentication failed for ${provider.displayName}. Check your API key in Settings.',
          status: GenerateState.error,
          generatingStep: GeneratingStep.idle,
        );
      } else if (e is NetworkFailure) {
        state = state.copyWith(
          errorMessage:
              'Network error. Please check your connection and try again.',
          status: GenerateState.error,
          generatingStep: GeneratingStep.idle,
        );
      } else {
        final raw = e.toString();
        final clean = raw.startsWith('Exception:')
            ? raw.substring(10).trim()
            : raw;
        final msg = clean.length > 220 ? '${clean.substring(0, 220)}…' : clean;
        state = state.copyWith(
          errorMessage: msg,
          status: GenerateState.error,
          generatingStep: GeneratingStep.idle,
        );
      }

      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Refinement Failed',
          'There was an error refining your post.',
        );
      }
      if (state.status != GenerateState.generating) {
        state = state.copyWith(generatingStep: GeneratingStep.idle);
      }
    }
  }

  Future<void> refineSelectedPills(
    Map<String, String> pillInstructionMap,
  ) async {
    final instructions = <String>[];
    for (final id in state.selectedPillIds) {
      final inst = pillInstructionMap[id];
      if (inst != null && inst.isNotEmpty) {
        instructions.add(inst);
      }
    }
    if (instructions.isNotEmpty) {
      await refineContent(instructions);
    }
  }

  Future<void> handleExternalSharedInput(String rawInput) async {
    _generationSessionId++;
    final parsed = SharedContentParser.parse(rawInput);
    final effectiveText = parsed.displayInput;

    state = state.copyWith(
      status: GenerateState.idle,
      generatingStep: GeneratingStep.idle,
      curatedPost: null,
      errorMessage: null,
      validationMessage: null,
      suggestedFallbackProvider: null,
      rateLimitWaitMessage: null,
      twitterExtractionUrl: null,
      isEditMode: false,
      selectedPillIds: const {},
      pendingInput: effectiveText,
    );

    await generatePost(effectiveText);
  }

  void reset() {
    _generationSessionId++;
    state = state.copyWith(
      status: GenerateState.idle,
      generatingStep: GeneratingStep.idle,
      curatedPost: null,
      errorMessage: null,
      validationMessage: null,
      suggestedFallbackProvider: null,
      rateLimitWaitMessage: null,
      twitterExtractionUrl: null,
      pendingInput: null,
      isEditMode: false,
      selectedPillIds: const {},
    );
  }

  /// $0 vision extraction: Auto (cloud chain -> ML Kit) or on-device only.
  ///
  /// Cloud success sets the curated post directly; on-device OCR fills
  /// [pendingInput] and runs the normal text pipeline.
  Future<void> extractTextFromImage(ImageSource source) async {
    final sessionId = ++_generationSessionId;
    state = state.copyWith(
      isExtractingImage: true,
      errorMessage: null,
      validationMessage: null,
    );
    final stopwatch = Stopwatch()..start();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1920);
      if (picked == null) {
        if (sessionId != _generationSessionId) return;
        state = state.copyWith(isExtractingImage: false);
        return;
      }
      final rawBytes = await picked.readAsBytes();
      final mimeType = VisionImagePrep.detectMimeType(picked.path);
      final visionMode = getIt.isRegistered<PreferencesService>()
          ? getIt<PreferencesService>().visionMode
          : VisionMode.auto;

      if (visionMode == VisionMode.onDeviceOnly) {
        await _extractOnDeviceOnly(picked.path, sessionId, stopwatch);
        return;
      }

      // Auto: cloud $0 chain first, ML Kit offline floor on failure.
      Uint8List bytes;
      try {
        bytes = await VisionImagePrep.downscaleForVision(rawBytes);
      } catch (_) {
        bytes = rawBytes;
      }
      if (getIt.isRegistered<VisionCuratorChain>()) {
        try {
          final chain = getIt<VisionCuratorChain>();
          final post = await chain
              .extractStructured(
                content: '',
                imageBytes: bytes,
                imageMimeType: mimeType,
                keepStructure: state.keepStructure,
              )
              .timeout(
                const Duration(seconds: 60),
                onTimeout: () =>
                    throw const NetworkFailure('Vision request timed out.'),
              );
          if (sessionId != _generationSessionId) return;
          stopwatch.stop();
          _logVisionUsage(stopwatch, true, post.rawMarkdown.length);
          getIt<LogService>().info('Vision extraction succeeded (cloud)');
          state = state.copyWith(
            curatedPost: post,
            pendingInput: post.bodyMarkdown.isNotEmpty
                ? post.bodyMarkdown
                : post.rawMarkdown,
            status: GenerateState.success,
            isExtractingImage: false,
          );
          return;
        } catch (e, st) {
          getIt<LogService>().error(
            'Cloud vision failed, trying on-device',
            e,
            st,
          );
          // Fall through to on-device floor unless auth errors with no
          // on-device available (ML Kit always available, so continue).
        }
      }
      await _extractOnDeviceOnly(picked.path, sessionId, stopwatch);
    } catch (e, st) {
      if (sessionId != _generationSessionId) return;
      stopwatch.stop();
      getIt<LogService>().error('Failed to extract text from image', e, st);
      final msg = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      state = state.copyWith(
        errorMessage: msg.length > 220 ? '${msg.substring(0, 220)}…' : msg,
        status: GenerateState.error,
        isExtractingImage: false,
      );
    }
  }

  Future<void> _extractOnDeviceOnly(
    String imagePath,
    int sessionId,
    Stopwatch stopwatch,
  ) async {
    if (!getIt.isRegistered<IVisionExtractor>()) {
      throw Exception('On-device OCR is unavailable.');
    }
    final text = await getIt<IVisionExtractor>().extractText(imagePath);
    if (sessionId != _generationSessionId) return;
    stopwatch.stop();
    if (text.trim().isEmpty) {
      _logVisionUsage(stopwatch, false, 0);
      state = state.copyWith(
        errorMessage:
            'No readable text found in this image. Try a clearer screenshot.',
        status: GenerateState.error,
        isExtractingImage: false,
      );
      return;
    }
    _logVisionUsage(stopwatch, true, text.length);
    getIt<LogService>().info('Vision extraction succeeded (on-device)');
    state = state.copyWith(
      pendingInput: text,
      isExtractingImage: false,
      status: GenerateState.idle,
    );
    await generatePost(text);
  }

  void _logVisionUsage(Stopwatch stopwatch, bool success, int chars) {
    try {
      _usageService.logUsage(
        UsageLog(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          providerId: 'vision',
          modelName: 'vision-chain',
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: (chars / 4).round(),
          isSuccess: success,
        ),
      );
    } catch (_) {}
  }
}

class TwitterExtractionException implements Exception {
  final String? url;
  TwitterExtractionException(this.url);
}
