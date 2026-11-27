import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/repositories/content_repository.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/daily_usage_service.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/notification_service.dart';
import 'package:oreamnos/data/services/rate_limit_guard.dart';
import 'package:oreamnos/data/services/share_intent_service.dart';
import 'package:oreamnos/data/services/token_usage_side_channel.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/domain/services/generation_prompt_manager.dart';
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
import 'package:oreamnos/ui/features/settings/view_models/settings_state.dart';
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
  late final RateLimitGuard _guard;
  bool _isBackgrounded = false;
  int _generationSessionId = 0;

  /// Logical key of the share currently driving generation. A duplicate
  /// delivery of the same content while it is still generating must not
  /// start a second session: overlapping attempts cancel each other's tokens
  /// and leave the UI stranded on the loading card.
  String? _activeShareInput;

  /// Extra attempts for share-initiated generations on transient failures
  /// (flaky FxTwitter, network gap right after app resume). Non-share
  /// generations keep single-shot semantics.
  static const int _maxShareRetries = 2;
  static const List<int> _shareRetryDelaysMs = [1500, 3000];

  /// Maximum automatic provider hops in the silent fallback chain
  /// (gemini → groq → openRouter → cerebras). Full chain length.
  static const int _maxFallbackHops = 4;

  /// Combined attempt budget for share-initiated generations: share retries
  /// and provider fallbacks share one cap so a burst cannot chain
  /// `_maxFallbackHops × _maxShareRetries` sequential 30s+ generations
  /// inside a single share handling.
  static const int _maxAttemptsPerShare = 4;

  /// Safety-net watchdog for the whole generation pipeline. The AI request
  /// already carries a receive window (`AppConstants.generationReceiveTimeout`)
  /// that cancels its own attempt, so this exists for the awaits *around* the
  /// AI call (Twitter scrape, tweet enrichment, article scrape, research
  /// enrichment) that had no ceiling — without it a hung step used to leave the
  /// UI stuck on the loading card's progress ceiling indefinitely.
  static const Duration _generationWatchdogTimeout = Duration(seconds: 150);

  Timer? _generationWatchdog;

  bool _canAttemptMore({
    required bool isFromShare,
    required int shareAttempt,
    required int fallbackDepth,
  }) {
    if (!isFromShare) return fallbackDepth < _maxFallbackHops;
    return shareAttempt + fallbackDepth < _maxAttemptsPerShare;
  }

  void _armGenerationWatchdog() {
    _disarmGenerationWatchdog();
    _generationWatchdog = Timer(
      _generationWatchdogTimeout,
      _onGenerationWatchdog,
    );
  }

  void _disarmGenerationWatchdog() {
    _generationWatchdog?.cancel();
    _generationWatchdog = null;
  }

  void _onGenerationWatchdog() {
    _generationWatchdog = null;
    final isBusy =
        state.status == GenerateState.generating ||
        state.status == GenerateState.researching;
    if (!isBusy) return;
    // Force-cancel the in-flight attempt and land on a terminal error so the
    // loading card can never hang on its progress ceiling. The in-flight
    // pipeline observes the cancel and funnels into its own error handling.
    final token = _attemptCancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('Generation watchdog fired (session $_generationSessionId)');
    }
    state = state.copyWith(
      status: GenerateState.error,
      generatingStep: GeneratingStep.idle,
      fallbackNotice: null,
      errorMessage: 'Generation did not complete in time. Please try again.',
      twitterExtractionUrl: null,
    );
  }

  /// Cancellation token for the in-flight network attempt. A newer session
  /// (new tap, share, refine, reset, dispose) cancels the previous attempt
  /// chain outright — orphaned requests otherwise keep burning provider
  /// quota in the background.
  CancelToken? _attemptCancelToken;

  CancelToken _newAttemptToken(int sessionId) {
    final stale = _attemptCancelToken;
    final token = CancelToken();
    _attemptCancelToken = token;
    if (stale != null && !stale.isCancelled) {
      stale.cancel('Superseded by a newer generation (session $sessionId)');
    }
    return token;
  }

  /// Cooldown per provider after a 429 — subsequent requests within the
  /// window skip the doomed provider entirely. Persisted in
  /// [RateLimitGuard]: RPM waits close in the near-minute window; RPD
  /// exhaustion closes until the real Pacific-midnight reset.
  bool _isCoolingDown(AiProvider provider) => _guard.isCoolingDown(provider);

  Future<void> _recordCooldown(AiProvider provider, int? retryDelayMs) =>
      _guard.recordCooldown(provider: provider, retryDelayMs: retryDelayMs);

  /// User-facing wait hint for a guarded provider. Explaining the reset
  /// time only for Gemini: it is the one provider with a real long
  /// (daily-reset) cooldown worth naming, unlike RPM retries.
  String? _waitMessageFor(AiProvider provider) {
    if (provider != AiProvider.gemini) return null;
    final daily = getIt.isRegistered<DailyUsageService>()
        ? getIt<DailyUsageService>()
        : null;
    if (daily == null) return null;
    final reset = daily.timeUntilPacificReset();
    if (reset <= Duration.zero) return null;
    final label = reset.inHours >= 1
        ? '${reset.inHours}h ${reset.inMinutes % 60}m'
        : '${reset.inMinutes}m';
    return 'Gemini quota exhausted — resets in $label (midnight PT).';
  }

  @override
  GenerateUiState build() {
    _usageService = getIt<UsageService>();
    _guard = getIt<RateLimitGuard>();
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _disarmGenerationWatchdog();
      // Cancel any in-flight provider request — a disposed Notifier's state
      // will never be read, so the only sane outcome for the network call is
      // cancellation (this also stops background quota burn).
      final token = _attemptCancelToken;
      if (token != null && !token.isCancelled) {
        token.cancel('GenerateViewModel disposed');
      }
    });

    if (getIt.isRegistered<PreferencesService>()) {
      final prefs = getIt<PreferencesService>();
      final uppercaseTitle = prefs.lastUppercaseTitle;
      if (prefs.persistGenerationOptions) {
        final length = PromptLength.values.firstWhere(
          (e) => e.name == prefs.lastPromptLength,
          orElse: () => PromptLength.medium,
        );
        return GenerateUiState(
          promptLength: length,
          isResearchModeEnabled: prefs.lastIsResearchMode,
          keepStructure: prefs.lastKeepStructure,
          uppercaseTitle: uppercaseTitle,
        );
      }
      // Uppercase is a display preference: remember it even when the broader
      // generation-options persistence is disabled.
      return GenerateUiState(uppercaseTitle: uppercaseTitle);
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

  /// Resolves the model for [provider]:
  /// - the settings state's selection when the persisted provider matches
  ///   (the normal path — identical to the old `selectedModel ?: default`);
  /// - for a VOLATILE fallback hop to a different provider, that provider's
  ///   stored per-provider selection, else its default model — never the
  ///   other provider's selected model ID, which would be invalid there.
  String _resolveModelId(AiProvider provider, SettingsState settings) {
    if (settings.selectedProvider == provider) {
      final selected = settings.selectedModel;
      if (selected != null && selected.isNotEmpty) return selected;
    }
    try {
      if (getIt.isRegistered<PreferencesService>()) {
        final stored = getIt<PreferencesService>().getSelectedModel(provider);
        if (stored != null && stored.trim().isNotEmpty) return stored;
      }
    } catch (_) {}
    return provider.defaultModelId;
  }

  /// Walks the fallback chain from [failedProvider], skipping providers in
  /// cooldown and providers without an API key. Returns the first healthy
  /// candidate, or null when the whole chain is unavailable (→ last-resort
  /// dialog).
  ///
  /// The switch is VOLATILE: the caller only uses it for the current
  /// generation attempt set (via `forceProvider`), so the user's persisted
  /// provider selection survives a rate-limit burst. Persisting a provider
  /// switch is reserved for the explicit dialog path (`retryWithProvider`).
  Future<AiProvider?> _switchToNextHealthyProvider(
    AiProvider failedProvider,
  ) async {
    final settingsNotifier = ref.read(settingsViewModelProvider.notifier);
    var candidate = failedProvider.nextFallback;
    for (var hop = 0; hop < AiProvider.values.length; hop++) {
      if (candidate == failedProvider) break;
      if (!_isCoolingDown(candidate)) {
        final apiKey = await settingsNotifier.getApiKeyForProvider(candidate);
        if (apiKey != null && apiKey.isNotEmpty) {
          return candidate;
        }
      }
      candidate = candidate.nextFallback;
    }
    return null;
  }

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

  bool get uppercaseTitle => state.uppercaseTitle;

  void toggleUppercaseTitle() {
    final next = !state.uppercaseTitle;
    state = state.copyWith(uppercaseTitle: next);
    if (getIt.isRegistered<PreferencesService>()) {
      // Always persist this one: it is a reading/display preference, not a
      // generation option.
      getIt<PreferencesService>().setLastUppercaseTitle(next);
    }
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
    if (trimmed.length > AppConstants.maxInputChars) {
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

  Future<void> generatePost(
    String input, {
    bool isFromShare = false,
    int shareAttempt = 0,
    int fallbackDepth = 0,
    AiProvider? forceProvider,
  }) async {
    final sessionId = ++_generationSessionId;
    final attemptToken = _newAttemptToken(sessionId);
    // A user-initiated generation takes ownership of the UI: a later replay
    // of the previous share must not be mistaken for a fresh share of it.
    if (!isFromShare) _activeShareInput = null;
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
      isFromShare: isFromShare,
      fallbackNotice: null,
    );

    // Every state that shows the loading card needs a live watchdog. Arm it
    // before the cooldown pre-flight (which awaits secure storage) instead of
    // after it: a throw or hang there used to leave `generating` with no
    // safety net, i.e. a loading card that never reaches a terminal state.
    _armGenerationWatchdog();
    final stopwatch = Stopwatch()..start();
    // Volatile fallback target — keep it outside the try so the catch can
    // still log the failed attempt with the provider that actually served it.
    var provider =
        forceProvider ?? ref.read(settingsViewModelProvider).selectedProvider;

    try {
      // Inline progress notice for intermediate attempts (not shown to the
      // modal dialog — just the loading card subtitle).
      String? notice;
      if (fallbackDepth > 0) {
        notice = 'Retrying with ${provider.displayName}…';
      } else if (shareAttempt > 0) {
        notice = 'Retrying (attempt ${shareAttempt + 1})…';
      } else if (_isCoolingDown(provider)) {
        // Cooldown-aware start: the selected provider is rate-limited —
        // hop to a healthy fallback instead of a doomed request. When
        // nothing is healthy, surface the wait instead of firing.
        final switched = await _switchToNextHealthyProvider(provider);
        if (sessionId != _generationSessionId) return;
        if (switched != null) {
          provider = switched;
          notice = 'Retrying with ${switched.displayName}…';
        } else {
          final waitMessage = _waitMessageFor(provider);
          _disarmGenerationWatchdog();
          state = state.copyWith(
            errorMessage:
                'Rate limit exceeded for ${provider.displayName}. '
                'Try another provider.'
                '${waitMessage != null ? ' $waitMessage' : ''}',
            suggestedFallbackProvider: _getNextProvider(provider),
            rateLimitWaitMessage: waitMessage,
            status: GenerateState.rateLimited,
            generatingStep: GeneratingStep.idle,
            fallbackNotice: null,
          );
          return;
        }
      }
      if (sessionId != _generationSessionId) return;
      if (notice != null) {
        state = state.copyWith(
          status: GenerateState.generating,
          fallbackNotice: notice,
        );
      }

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
        if (sessionId != _generationSessionId) return;

        if (tweet == null || !tweet.isValid) {
          tweet = await TwitterExtractor.extractViaVxTwitter(targetTwitterUrl);
          if (sessionId != _generationSessionId) return;
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
          if (sessionId != _generationSessionId) return;

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
              final configured = await searchRepo.isConfigured();
              if (sessionId != _generationSessionId) return;
              if (configured) {
                contentToCurate = await searchRepo.extractFromUrl(
                  targetTwitterUrl,
                );
                if (sessionId != _generationSessionId) return;
              } else {
                throw TwitterExtractionException(sourceUrl);
              }
            } catch (e) {
              if (sessionId != _generationSessionId) return;
              throw TwitterExtractionException(sourceUrl);
            }
          }
        }

        if (sessionId != _generationSessionId) return;
        state = state.copyWith(generatingStep: GeneratingStep.prompting);
      } else if (parsed.primaryUrl != null ||
          WebScraperService.isUrl(trimmedInput)) {
        final targetUrl = parsed.primaryUrl ?? trimmedInput;
        state = state.copyWith(generatingStep: GeneratingStep.scraping);
        try {
          final article = await WebScraperService.extractArticleFromUrl(
            targetUrl,
          ).timeout(const Duration(seconds: 10));
          if (sessionId != _generationSessionId) return;
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
          if (sessionId != _generationSessionId) return;
          if (parsed.accompanyingText.isNotEmpty) {
            contentToCurate = parsed.accompanyingText;
            sourceUrl = targetUrl;
          } else {
            throw Exception(
              'URL extraction timed out. Please paste the article text manually.',
            );
          }
        }
        if (sessionId != _generationSessionId) return;
        state = state.copyWith(generatingStep: GeneratingStep.prompting);
      }

      // 2. AI Research Mode Enrichment (if enabled)
      if (state.isResearchModeEnabled) {
        if (sessionId != _generationSessionId) return;
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
        if (sessionId != _generationSessionId) return;

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
        if (sessionId != _generationSessionId) return;
        state = state.copyWith(searchSources: []);
      }

      final settings = ref.read(settingsViewModelProvider);
      final modelId = _resolveModelId(provider, settings);

      final apiKey = await ref
          .read(settingsViewModelProvider.notifier)
          .getApiKeyForProvider(provider);
      if (sessionId != _generationSessionId) return;
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
      // Quota squeeze (Gemini only): collapse whitespace noise in the source
      // so the request burns fewer tokens. Shapes text only — facts
      // unchanged — so the next-request quality is identical.
      if (provider == AiProvider.gemini) {
        contentToCurate = GenerationPromptManager.squeezeForGemini(
          contentToCurate,
        );
      }

      // API resilience: via pooled IContentRepository + Result fold + timeout
      // aligned with the per-request generation receive window (long posts
      // legitimately take >30s; 30s used to orphan mid-flight generations).
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
            cancelToken: attemptToken,
          )
          .timeout(
            AppConstants.generationReceiveTimeout,
            onTimeout: () {
              if (!attemptToken.isCancelled) {
                attemptToken.cancel('VM receive window expired');
              }
              return throw NetworkFailure(
                'Request timed out after ${AppConstants.generationReceiveTimeout.inSeconds}s',
              );
            },
          );

      if (sessionId != _generationSessionId) {
        // A newer session superseded this attempt (share re-delivery, fallback
        // hop, manual regenerate). The newer session owns the UI state from
        // here on; the usage log above already recorded this attempt's real
        // outcome, so the only correct action is to drop the stale result.
        final currentSessionId = _generationSessionId;
        getIt<LogService>().info(
          'Superseded generation attempt $sessionId finished before current session $currentSessionId could apply it',
        );
        return;
      }

      // Handle Result via typed Failure — no string contains
      if (repoResult is ResultError<CuratedPost>) {
        final failure = repoResult.failure;
        stopwatch.stop();
        final requestId = const Uuid().v4();
        _usageService.logUsage(
          UsageLog(
            id: requestId,
            timestamp: DateTime.now(),
            providerId: provider.name,
            modelName: modelId,
            latencyMs: stopwatch.elapsedMilliseconds,
            estimatedTokens: 0,
            isSuccess: false,
            requestId: requestId,
            error: _errorText(failure),
          ),
        );
        getIt<LogService>().error(
          'Failed to generate post',
          error: failure,
          stackTrace: null,
        );
        final isTransientShareFailure =
            isFromShare &&
            shareAttempt < _maxShareRetries &&
            _canAttemptMore(
              isFromShare: isFromShare,
              shareAttempt: shareAttempt,
              fallbackDepth: fallbackDepth,
            ) &&
            (failure is NetworkFailure);
        if (failure is RateLimitFailure || failure is PaymentRequiredFailure) {
          if (failure is RateLimitFailure) {
            await _recordCooldown(provider, failure.retryDelayMs);
          }
          // Silent auto-fallback: walk the chain to the first healthy
          // provider with a key instead of stopping at the dialog. The hop
          // is volatile (forceProvider) — the user's persisted provider is
          // left untouched.
          if (_canAttemptMore(
            isFromShare: isFromShare,
            shareAttempt: shareAttempt,
            fallbackDepth: fallbackDepth,
          )) {
            final fallback = await _switchToNextHealthyProvider(provider);
            if (fallback != null && sessionId == _generationSessionId) {
              getIt<LogService>().info(
                '${provider.displayName} quota exhausted — auto-falling back to ${fallback.displayName}',
              );
              await generatePost(
                trimmedInput,
                isFromShare: isFromShare,
                shareAttempt: shareAttempt,
                fallbackDepth: fallbackDepth + 1,
                forceProvider: fallback,
              );
              return;
            }
          }
          // Chain exhausted → last-resort dialog state. A superseded
          // attempt must not disarm the newer session's watchdog.
          if (sessionId != _generationSessionId) return;
          final waitMessage = failure is RateLimitFailure
              ? failure.waitTimeMessage
              : null;
          _disarmGenerationWatchdog();
          state = state.copyWith(
            errorMessage:
                'Rate limit exceeded for ${provider.displayName}. Try another provider.${waitMessage != null ? ' $waitMessage' : ''}',
            suggestedFallbackProvider: _getNextProvider(provider),
            rateLimitWaitMessage: waitMessage,
            status: GenerateState.rateLimited,
            generatingStep: GeneratingStep.idle,
            fallbackNotice: null,
          );
        } else if (isTransientShareFailure) {
          // Share-initiated transient failure: auto-retry in the background.
          await Future.delayed(
            Duration(
              milliseconds:
                  _shareRetryDelaysMs[shareAttempt.clamp(
                    0,
                    _shareRetryDelaysMs.length - 1,
                  )],
            ),
          );
          if (sessionId != _generationSessionId) return;
          await generatePost(
            input,
            isFromShare: true,
            shareAttempt: shareAttempt + 1,
            fallbackDepth: fallbackDepth,
            // Retry the same provider (a transient network failure doesn't
            // imply a provider choice change); preserve any cooldown hop.
            forceProvider: provider,
          );
          return;
        } else if (failure is AuthFailure) {
          state = state.copyWith(
            errorMessage:
                'Authentication failed for ${provider.displayName}. Check your API key in Settings.',
            status: GenerateState.error,
            generatingStep: GeneratingStep.idle,
            fallbackNotice: null,
          );
        } else if (failure is NetworkFailure) {
          state = state.copyWith(
            errorMessage:
                'Network error. Please check your connection and try again.',
            status: GenerateState.error,
            generatingStep: GeneratingStep.idle,
            fallbackNotice: null,
          );
        } else {
          final msg = failure.message.length > 220
              ? '${failure.message.substring(0, 220)}...'
              : failure.message;
          state = state.copyWith(
            errorMessage: msg,
            status: GenerateState.error,
            generatingStep: GeneratingStep.idle,
            fallbackNotice: null,
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

      // The RPM window has moved on — let the next request through.
      _guard.clearOnSuccess(provider);

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
      final requestId = const Uuid().v4();
      int estimatedTokens = ((input.length + (curated.rawMarkdown.length)) / 4)
          .round();
      // Side-channel: use real total_tokens if captured
      final tokenSnapshot = _consumeSideChannelTokens();
      if (tokenSnapshot.total != null && tokenSnapshot.total! > 0) {
        estimatedTokens = tokenSnapshot.total!;
      }
      _usageService.logUsage(
        UsageLog(
          id: requestId,
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: modelId,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: estimatedTokens,
          isSuccess: true,
          requestId: requestId,
          promptTokens: tokenSnapshot.prompt,
          completionTokens: tokenSnapshot.completion,
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
        fallbackNotice: null,
      );
      _disarmGenerationWatchdog();

      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Post Ready',
          'Your AI-curated social media post has been generated successfully.',
        );
      }
    } catch (e, st) {
      // Never disarm a newer session's watchdog: this attempt's cancellation
      // is what strands the current pipeline without a safety net.
      if (sessionId != _generationSessionId) return;
      _disarmGenerationWatchdog();
      // Only for non-API failures (Twitter, scrape, timeout before repo call)
      stopwatch.stop();
      final requestId = const Uuid().v4();
      _usageService.logUsage(
        UsageLog(
          id: requestId,
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: ref.read(settingsViewModelProvider).selectedModel,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: 0,
          isSuccess: false,
          requestId: requestId,
          error: _errorText(e),
        ),
      );

      getIt<LogService>().error(
        'Failed to generate post',
        error: e,
        stackTrace: st,
      );

      // Share-initiated transient failures (flaky FxTwitter/VxTwitter,
      // network gap right after app resume): auto-retry in the background.
      final isTransientException =
          e is TwitterExtractionException ||
          e is TimeoutException ||
          e is NetworkFailure;
      if (isFromShare &&
          shareAttempt < _maxShareRetries &&
          _canAttemptMore(
            isFromShare: isFromShare,
            shareAttempt: shareAttempt,
            fallbackDepth: fallbackDepth,
          ) &&
          isTransientException) {
        await Future.delayed(
          Duration(
            milliseconds:
                _shareRetryDelaysMs[shareAttempt.clamp(
                  0,
                  _shareRetryDelaysMs.length - 1,
                )],
          ),
        );
        if (sessionId != _generationSessionId) return;
        await generatePost(
          input,
          isFromShare: true,
          shareAttempt: shareAttempt + 1,
          fallbackDepth: fallbackDepth,
          // Retry the same provider (a transient network failure doesn't
          // imply a provider choice change); preserve any cooldown hop.
          forceProvider: provider,
        );
        return;
      }

      if (e is TwitterExtractionException) {
        state = state.copyWith(
          status: GenerateState.error,
          twitterExtractionUrl: e.url,
          errorMessage:
              'Could not extract tweet content from X. '
              'Please copy the tweet text directly and paste it here.\n\n'
              'Tip: Tap "..." on the tweet → "Copy text"',
          generatingStep: GeneratingStep.idle,
          fallbackNotice: null,
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
          fallbackNotice: null,
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

  Future<void> refineContent(
    List<String> instructions, {
    int fallbackDepth = 0,
    AiProvider? forceProvider,
  }) async {
    final cp = state.curatedPost;
    if (cp == null || instructions.isEmpty) return;

    final sessionId = ++_generationSessionId;
    final attemptToken = _newAttemptToken(sessionId);

    _pushHistory(cp);
    state = state.copyWith(
      status: GenerateState.generating,
      generatingStep: GeneratingStep.prompting,
      errorMessage: null,
      validationMessage: null,
      fallbackNotice: null,
    );

    _armGenerationWatchdog();

    final stopwatch = Stopwatch()..start();
    // Volatile fallback target — see _switchToNextHealthyProvider.
    var provider =
        forceProvider ?? ref.read(settingsViewModelProvider).selectedProvider;
    // Declared up front so the catch can still log a pre-flight failure.
    var modelId = _resolveModelId(
      provider,
      ref.read(settingsViewModelProvider),
    );

    try {
      // Pre-flight quota gate — same as generatePost: never burn a request on
      // a provider the guard still has cooling down. Kept inside the try so a
      // throw here lands on a terminal error state instead of stranding the
      // loading card.
      if (_isCoolingDown(provider)) {
        final switched = await _switchToNextHealthyProvider(provider);
        if (sessionId != _generationSessionId) return;
        if (switched != null) {
          provider = switched;
          modelId = _resolveModelId(
            provider,
            ref.read(settingsViewModelProvider),
          );
          state = state.copyWith(
            status: GenerateState.generating,
            generatingStep: GeneratingStep.prompting,
            fallbackNotice: 'Retrying with ${switched.displayName}…',
          );
        } else {
          final waitMessage = _waitMessageFor(provider);
          _disarmGenerationWatchdog();
          state = state.copyWith(
            status: GenerateState.rateLimited,
            generatingStep: GeneratingStep.idle,
            fallbackNotice: null,
            errorMessage:
                'Rate limit exceeded for ${provider.displayName}. '
                'Try another provider.'
                '${waitMessage != null ? ' $waitMessage' : ''}',
            suggestedFallbackProvider: _getNextProvider(provider),
            rateLimitWaitMessage: waitMessage,
          );
          return;
        }
      }

      final settings = ref.read(settingsViewModelProvider);
      modelId = _resolveModelId(provider, settings);
      final apiKey = await ref
          .read(settingsViewModelProvider.notifier)
          .getApiKeyForProvider(provider);
      if (sessionId != _generationSessionId) return;
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
            // Inherit the user's selected length and fan-mode context so the
            // refinement prompt matches how the original post was generated.
            length: state.promptLength.name,
            isFanModeEnabled: settings.isFanModeEnabled,
            fanClubName: settings.fanClubName,
            cancelToken: attemptToken,
          )
          .timeout(
            AppConstants.generationReceiveTimeout,
            onTimeout: () {
              if (!attemptToken.isCancelled) {
                attemptToken.cancel('VM receive window expired');
              }
              return throw NetworkFailure(
                'Request timed out after ${AppConstants.generationReceiveTimeout.inSeconds}s',
              );
            },
          );

      if (sessionId != _generationSessionId) return;

      if (repoResult is ResultError<CuratedPost>) {
        throw repoResult.failure;
      }
      final refined = (repoResult as ResultSuccess<CuratedPost>).data;
      _guard.clearOnSuccess(provider);

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
      final requestId = const Uuid().v4();
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
      final tokenSnapshot = _consumeSideChannelTokens();
      if (tokenSnapshot.total != null && tokenSnapshot.total! > 0) {
        estimatedTokens = tokenSnapshot.total!;
      }
      _usageService.logUsage(
        UsageLog(
          id: requestId,
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: modelId,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: estimatedTokens,
          isSuccess: true,
          requestId: requestId,
          promptTokens: tokenSnapshot.prompt,
          completionTokens: tokenSnapshot.completion,
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
        fallbackNotice: null,
      );
      _disarmGenerationWatchdog();

      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Refinement Ready',
          'Your refined social media post is ready.',
        );
      }
    } catch (e, st) {
      // See generatePost: a stale attempt must leave the current watchdog
      // armed so a hung refinement always reaches a terminal state.
      if (sessionId != _generationSessionId) return;
      _disarmGenerationWatchdog();
      stopwatch.stop();
      final requestId = const Uuid().v4();
      _usageService.logUsage(
        UsageLog(
          id: requestId,
          timestamp: DateTime.now(),
          providerId: provider.name,
          modelName: modelId,
          latencyMs: stopwatch.elapsedMilliseconds,
          estimatedTokens: 0,
          isSuccess: false,
          requestId: requestId,
          error: _errorText(e),
        ),
      );

      getIt<LogService>().error(
        'Failed to refine post',
        error: e,
        stackTrace: st,
      );

      if (e is RateLimitFailure || e is PaymentRequiredFailure) {
        if (e is RateLimitFailure) {
          await _recordCooldown(provider, e.retryDelayMs);
        }
        // Silent auto-fallback (same chain as generatePost, volatile).
        if (fallbackDepth < _maxFallbackHops) {
          final fallback = await _switchToNextHealthyProvider(provider);
          if (fallback != null && sessionId == _generationSessionId) {
            getIt<LogService>().info(
              '${provider.displayName} quota exhausted — auto-falling back to ${fallback.displayName}',
            );
            state = state.copyWith(
              status: GenerateState.generating,
              fallbackNotice:
                  '${provider.displayName} rate-limited — retrying with ${fallback.displayName}…',
            );
            await refineContent(
              instructions,
              fallbackDepth: fallbackDepth + 1,
              forceProvider: fallback,
            );
            return;
          }
        }
        if (sessionId != _generationSessionId) return;
        _disarmGenerationWatchdog();
        state = state.copyWith(
          errorMessage:
              'Rate limit exceeded for ${provider.displayName}. ${e is RateLimitFailure ? e.waitTimeMessage : ''}',
          suggestedFallbackProvider: _getNextProvider(provider),
          rateLimitWaitMessage: e is RateLimitFailure
              ? e.waitTimeMessage
              : null,
          status: GenerateState.rateLimited,
          generatingStep: GeneratingStep.idle,
          fallbackNotice: null,
        );
      } else if (e is AuthFailure) {
        state = state.copyWith(
          errorMessage:
              'Authentication failed for ${provider.displayName}. Check your API key in Settings.',
          status: GenerateState.error,
          generatingStep: GeneratingStep.idle,
          fallbackNotice: null,
        );
      } else if (e is NetworkFailure) {
        state = state.copyWith(
          errorMessage:
              'Network error. Please check your connection and try again.',
          status: GenerateState.error,
          generatingStep: GeneratingStep.idle,
          fallbackNotice: null,
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
          fallbackNotice: null,
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
    final parsed = SharedContentParser.parse(rawInput);
    final effectiveText = parsed.displayInput;
    final shareKey = ShareIntentService.normalizeDedupKey(rawInput);

    // Android can deliver the same share more than once (stream bounce after
    // the service's dedup window or with differing tracking parameters).
    // Starting a second session here would bump the session id, cancel the
    // first attempt's token and leave the UI on the loading card.
    if (_activeShareInput == shareKey) {
      final status = state.status;
      if (status == GenerateState.generating ||
          status == GenerateState.researching) {
        getIt<LogService>().info(
          'Ignoring duplicate share while its generation is in flight',
        );
        return;
      }
      // A replay arriving after the post was generated must not throw that
      // finished post away: the usage row already records the real result,
      // and re-generating would only show a fresh loading card with the same
      // content. Explicit "Regenerate" / a new entry remain available.
      if (status == GenerateState.success && state.curatedPost != null) {
        getIt<LogService>().info(
          'Ignoring replay of a share whose post is already generated',
        );
        return;
      }
    }
    _activeShareInput = shareKey;

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
      isEditMode: false,
      selectedPillIds: const {},
      pendingInput: effectiveText,
      isFromShare: true,
      fallbackNotice: null,
    );

    try {
      await generatePost(effectiveText, isFromShare: true);
    } finally {
      final status = state.status;
      // Keep the key on success: it is what lets a late replay be recognised
      // as a replay instead of wiping the finished post. Every other settled
      // state releases it so a deliberate re-share can start cleanly.
      if (_activeShareInput == shareKey &&
          status != GenerateState.generating &&
          status != GenerateState.researching &&
          status != GenerateState.success) {
        _activeShareInput = null;
      }
    }
  }

  /// User-initiated stop: cancels the in-flight attempt (and the watchdog) and
  /// drops the UI out of the generating state so the loading card can dismiss.
  /// The session bump makes any in-flight pipeline continuation stale, so its
  /// late success/error writes no longer touch the (now idle) state.
  void cancelGeneration() {
    _activeShareInput = null;
    _disarmGenerationWatchdog();
    final token = _attemptCancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('Generation cancelled by user');
    }
    _generationSessionId++;
    state = state.copyWith(
      status: GenerateState.idle,
      generatingStep: GeneratingStep.idle,
      errorMessage: 'Generation cancelled.',
      validationMessage: null,
      fallbackNotice: null,
      twitterExtractionUrl: null,
      pendingInput: null,
      isEditMode: false,
      selectedPillIds: const {},
      isFromShare: false,
    );
  }

  void reset() {
    _activeShareInput = null;
    _generationSessionId++;
    _disarmGenerationWatchdog();
    final stale = _attemptCancelToken;
    if (stale != null && !stale.isCancelled) {
      stale.cancel('Reset');
    }
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
      isFromShare: false,
      fallbackNotice: null,
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
          final visionToken = _newAttemptToken(sessionId);
          final post = await chain
              .extractStructured(
                content: '',
                imageBytes: bytes,
                imageMimeType: mimeType,
                keepStructure: state.keepStructure,
                cancelToken: visionToken,
              )
              .timeout(
                const Duration(seconds: 60),
                onTimeout: () {
                  if (!visionToken.isCancelled) {
                    visionToken.cancel('Vision request timed out');
                  }
                  return throw const NetworkFailure(
                    'Vision request timed out.',
                  );
                },
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
            error: e,
            stackTrace: st,
          );
          // Fall through to on-device floor unless auth errors with no
          // on-device available (ML Kit always available, so continue).
        }
      }
      await _extractOnDeviceOnly(picked.path, sessionId, stopwatch);
    } catch (e, st) {
      if (sessionId != _generationSessionId) return;
      stopwatch.stop();
      getIt<LogService>().error(
        'Failed to extract text from image',
        error: e,
        stackTrace: st,
      );
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
      _logVisionUsage(
        stopwatch,
        false,
        0,
        error:
            'No readable text found in this image. '
            'Try a clearer screenshot.',
      );
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

  void _logVisionUsage(
    Stopwatch stopwatch,
    bool success,
    int chars, {
    String? error,
  }) {
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
          error: error,
        ),
      );
    } catch (_) {}
  }

  /// Consumes the side channel and returns real token counts when present.
  ({int? total, int? prompt, int? completion}) _consumeSideChannelTokens() {
    try {
      if (getIt.isRegistered<TokenUsageSideChannel>()) {
        return getIt<TokenUsageSideChannel>().consume() ??
            (total: null, prompt: null, completion: null);
      }
    } catch (_) {}
    return (total: null, prompt: null, completion: null);
  }

  /// Short single-line description of a failure for [UsageLog.error].
  static String? _errorText(Object? error) {
    if (error == null) return null;
    final raw = error is Failure ? error.message : error.toString();
    final text = raw.replaceAll('\n', ' ').trim();
    if (text.isEmpty) return null;
    return text.length > 200 ? '${text.substring(0, 197)}...' : text;
  }
}

class TwitterExtractionException implements Exception {
  final String? url;
  TwitterExtractionException(this.url);
}
