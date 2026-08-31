import 'dart:async';
import 'dart:convert';

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
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
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

  @override
  GenerateUiState build() {
    _usageService = getIt<UsageService>();
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });
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
    return cp.toMarkdownFiltered(
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
        return 'Keep the generated body text very concise and punchy (1-2 short sentences max).';
      case PromptLength.medium:
        return 'Provide a standard length post (2-3 sentences).';
      case PromptLength.long:
        return 'Write a detailed and comprehensive post with more context and information (3-5 sentences).';
    }
  }

  void setPromptLength(PromptLength length) {
    state = state.copyWith(promptLength: length);
  }

  AiProvider _getNextProvider(AiProvider current) => current.nextFallback;

  Future<void> retryWithProvider(AiProvider provider) async {
    await ref
        .read(settingsViewModelProvider.notifier)
        .setSelectedProvider(provider);
    final pi = state.pendingInput;
    if (pi != null) {
      await generatePost(pi);
    }
  }

  void toggleResearchMode() {
    state = state.copyWith(isResearchModeEnabled: !state.isResearchModeEnabled);
  }

  void toggleTitle() {
    state = state.copyWith(showTitle: !state.showTitle);
  }

  void toggleKeepStructure() {
    state = state.copyWith(keepStructure: !state.keepStructure);
  }

  void toggleHashtags() {
    state = state.copyWith(showHashtags: !state.showHashtags);
  }

  void toggleSource() {
    state = state.copyWith(showSource: !state.showSource);
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
    final modelId = ref.read(settingsViewModelProvider).selectedModel;
    if (modelId == null || modelId.isEmpty) {
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
    final v = validateForGenerate(input);
    if (!v.isValid) {
      state = state.copyWith(
        errorMessage: v.message,
        validationMessage: v.message,
        status: GenerateState.error,
      );
      return;
    }
    final apiCheck = await validateApiKey();
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
      twitterExtractionUrl: null,
      pendingInput: trimmedInput,
    );

    final stopwatch = Stopwatch()..start();
    final provider = ref.read(settingsViewModelProvider).selectedProvider;

    try {
      dynamic contentToCurate = state.pendingInput!.trim();
      String? sourceUrl;

      if (state.isResearchModeEnabled) {
        state = state.copyWith(status: GenerateState.researching);

        final enrichUsecase = getIt<EnrichContextUseCase>();
        final intent = IntentClassifier.classify(contentToCurate as String);
        final enrichmentResult = await enrichUsecase.execute(
          contentToCurate,
          intent,
        );

        contentToCurate = enrichmentResult.content;
        final sources = enrichmentResult.sources;
        if (intent == InputIntent.url && sources.isNotEmpty) {
          sourceUrl = sources.first;
        }
        state = state.copyWith(
          searchSources: sources,
          status: GenerateState.generating,
          generatingStep: GeneratingStep.prompting,
        );
      } else {
        state = state.copyWith(searchSources: []);

        if (TwitterExtractor.isTwitterUrl(contentToCurate)) {
          state = state.copyWith(generatingStep: GeneratingStep.scraping);

          sourceUrl = contentToCurate;

          TweetContent? tweet;

          tweet = await TwitterExtractor.extractViaFxTwitter(contentToCurate);

          if (tweet == null || !tweet.isValid) {
            tweet = await TwitterExtractor.extractViaVxTwitter(contentToCurate);
          }

          if (tweet != null && tweet.isValid) {
            contentToCurate = TwitterExtractor.formatForAiPrompt(tweet);
          } else {
            try {
              final searchRepo = getIt<ISearchRepository>();
              contentToCurate = await searchRepo.extractFromUrl(
                contentToCurate,
              );
            } catch (e) {
              throw TwitterExtractionException(sourceUrl);
            }
          }

          state = state.copyWith(generatingStep: GeneratingStep.prompting);
        } else if (WebScraperService.isUrl(contentToCurate)) {
          state = state.copyWith(generatingStep: GeneratingStep.scraping);
          try {
            final article = await WebScraperService.extractArticleFromUrl(
              contentToCurate,
            ).timeout(const Duration(seconds: 10));
            contentToCurate = article;
            sourceUrl = article.url;
            if (article.text.trim().isEmpty) {
              getIt<LogService>().warning(
                'Scrape returned empty, falling back to raw input',
              );
              contentToCurate = state.pendingInput!;
              sourceUrl = state.pendingInput;
            }
          } on TimeoutException {
            throw Exception(
              'URL extraction timed out. Please paste the article text manually.',
            );
          }
          state = state.copyWith(generatingStep: GeneratingStep.prompting);
        }
      }

      final modelId = ref.read(settingsViewModelProvider).selectedModel;
      if (modelId == null || modelId.isEmpty) {
        throw Exception(
          'No model selected. Please go to Settings to select a model.',
        );
      }

      final apiKey = await ref
          .read(settingsViewModelProvider.notifier)
          .getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured for ${provider.displayName}.');
      }

      if (contentToCurate is ExtractedArticle) {
        contentToCurate = ExtractedArticle(
          text:
              '${contentToCurate.text}\n\nLENGTH REQUIREMENT: $_lengthInstruction',
          url: contentToCurate.url,
          domain: contentToCurate.domain,
          pageTitle: contentToCurate.pageTitle,
          description: contentToCurate.description,
          faviconUrl: contentToCurate.faviconUrl,
        );
      } else {
        contentToCurate =
            '$contentToCurate\n\nLENGTH REQUIREMENT: $_lengthInstruction';
      }
      // API resilience: via pooled IContentRepository + Result fold + 30s timeout
      final repo = ref.read(contentRepositoryProvider);
      final settings = ref.read(settingsViewModelProvider);

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
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw const NetworkFailure('Request timed out after 30s'),
          );

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
                'Rate limit exceeded for ${provider.displayName}. Try another provider.',
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

  Future<void> refineContent(String instruction) async {
    final cp = state.curatedPost;
    if (cp == null) return;

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
      final modelId = ref.read(settingsViewModelProvider).selectedModel;
      if (modelId == null || modelId.isEmpty) {
        throw Exception(
          'No model selected. Please go to Settings to select a model.',
        );
      }

      final apiKey = await ref
          .read(settingsViewModelProvider.notifier)
          .getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured for ${provider.displayName}.');
      }

      final currentJson = jsonEncode(cp.toJson());
      final refinementContent =
          'Arahan penambahbaikan: "$instruction".\n'
          'Kekalkan sumber yang sama (${cp.source.url ?? cp.source.label}).\n'
          'JSON semasa:\n$currentJson\n\n'
          'Kembalikan JSON dengan struktur yang sama (title, body, source) — perbaiki title/body mengikut arahan, jangan ubah source.url.';

      final repo = ref.read(contentRepositoryProvider);
      final settings = ref.read(settingsViewModelProvider);

      final repoResult = await repo
          .generateStructuredPost(
            content: refinementContent,
            modelId: modelId,
            apiKey: apiKey,
            sourceUrl: cp.source.url,
            provider: provider,
            keepStructure: state.keepStructure,
            isFanModeEnabled: settings.isFanModeEnabled,
            fanClubName: settings.fanClubName,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw const NetworkFailure('Request timed out after 30s'),
          );
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
      int estimatedTokens =
          ((refinementContent.length + (merged.rawMarkdown.length)) / 4)
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

      state = state.copyWith(
        curatedPost: merged,
        status: GenerateState.success,
        generatingStep: GeneratingStep.idle,
      );

      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Refinement Ready',
          'Your refined social media post is ready.',
        );
      }
    } catch (e, st) {
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
          errorMessage: 'Rate limit exceeded for ${provider.displayName}.',
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

  void reset() {
    state = state.copyWith(
      status: GenerateState.idle,
      generatingStep: GeneratingStep.idle,
      curatedPost: null,
      errorMessage: null,
      validationMessage: null,
      suggestedFallbackProvider: null,
    );
  }

  // Vision/ML Kit extraction removed — vision models excluded per v2 verdict.
  Future<void> extractTextFromImage(dynamic _) async {
    state = state.copyWith(
      errorMessage: 'Image extraction is disabled (vision models excluded).',
      status: GenerateState.error,
    );
  }
}

class TwitterExtractionException implements Exception {
  final String? url;
  TwitterExtractionException(this.url);
}
