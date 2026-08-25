import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ai_provider.dart';
import '../../data/services/curator_factory.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/web_scraper_service.dart';
import '../../domain/models/curated_post.dart';
import '../../domain/models/usage_log.dart';
import '../error/failures.dart';
import 'app_providers.dart';
import 'settings_provider.dart';

// Re-export for consumers
enum GenerateStatus { idle, generating, success, error, rateLimited }
enum GeneratingStep { idle, scraping, prompting }

class GenerateState {
  final GenerateStatus status;
  final GeneratingStep step;
  final CuratedPost? curatedPost;
  final String? errorMessage;
  final String? validationMessage;
  final AiProvider? suggestedFallbackProvider;
  final String? pendingInput;
  final bool showTitle;
  final bool showHashtags;
  final bool showSource;
  final List<String> historyStack;
  final List<String> recentInputs;
  final bool isExtractingImage;

  const GenerateState({
    this.status = GenerateStatus.idle,
    this.step = GeneratingStep.idle,
    this.curatedPost,
    this.errorMessage,
    this.validationMessage,
    this.suggestedFallbackProvider,
    this.pendingInput,
    this.showTitle = true,
    this.showHashtags = true,
    this.showSource = true,
    this.historyStack = const [],
    this.recentInputs = const [],
    this.isExtractingImage = false,
  });

  String? get generatedContent => curatedPost?.rawMarkdown;
  String? get formattedContent {
    if (curatedPost == null) return null;
    return curatedPost!.toMarkdownFiltered(showTitle: showTitle, showHashtags: showHashtags, showSource: showSource);
  }
  String? get formattedBody => curatedPost?.bodyMarkdown;
  SourceAttribution? get sourceAttribution => curatedPost?.source;
  bool get canUndo => historyStack.isNotEmpty;

  GenerateState copyWith({
    GenerateStatus? status,
    GeneratingStep? step,
    CuratedPost? curatedPost,
    bool clearCuratedPost = false,
    String? errorMessage,
    bool clearError = false,
    String? validationMessage,
    bool clearValidation = false,
    AiProvider? suggestedFallbackProvider,
    bool clearFallback = false,
    String? pendingInput,
    bool clearPending = false,
    bool? showTitle,
    bool? showHashtags,
    bool? showSource,
    List<String>? historyStack,
    List<String>? recentInputs,
    bool? isExtractingImage,
  }) {
    return GenerateState(
      status: status ?? this.status,
      step: step ?? this.step,
      curatedPost: clearCuratedPost ? null : (curatedPost ?? this.curatedPost),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      validationMessage: clearValidation ? null : (validationMessage ?? this.validationMessage),
      suggestedFallbackProvider: clearFallback ? null : (suggestedFallbackProvider ?? this.suggestedFallbackProvider),
      pendingInput: clearPending ? null : (pendingInput ?? this.pendingInput),
      showTitle: showTitle ?? this.showTitle,
      showHashtags: showHashtags ?? this.showHashtags,
      showSource: showSource ?? this.showSource,
      historyStack: historyStack ?? this.historyStack,
      recentInputs: recentInputs ?? this.recentInputs,
      isExtractingImage: isExtractingImage ?? this.isExtractingImage,
    );
  }
}

class GenerateNotifier extends Notifier<GenerateState> {
  @override
  GenerateState build() => const GenerateState();

  bool _isBackgrounded = false;
  void setBackgrounded(bool v) => _isBackgrounded = v;

  String get providerDisplayName => ref.read(settingsProvider).selectedProvider.displayName;

  AiProvider _getNextProvider(AiProvider current) {
    switch (current) {
      case AiProvider.gemini: return AiProvider.groq;
      case AiProvider.groq: return AiProvider.openRouter;
      case AiProvider.openRouter: return AiProvider.cerebras;
      case AiProvider.cerebras: return AiProvider.gemini;
    }
  }

  Future<void> retryWithProvider(AiProvider provider) async {
    await ref.read(settingsProvider.notifier).setSelectedProvider(provider);
    final pending = state.pendingInput;
    if (pending != null) await generatePost(pending);
  }

  void setPendingInput(String input) {
    state = state.copyWith(pendingInput: input);
  }

  void clearPendingInput() => state = state.copyWith(clearPending: true);

  void toggleTitle() => state = state.copyWith(showTitle: !state.showTitle);
  void toggleHashtags() => state = state.copyWith(showHashtags: !state.showHashtags);
  void toggleSource() => state = state.copyWith(showSource: !state.showSource);

  // Validation — mirrors GenerateViewModel.validateForGenerate
  ({bool isValid, String? message}) validateForGenerate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return (isValid: false, message: 'Please enter news text or a URL.');
    if (trimmed.length > 8000) return (isValid: false, message: 'Input too long (max 8000 characters). Please shorten or paste a URL.');
    final modelId = ref.read(settingsProvider).selectedModel;
    final provider = ref.read(settingsProvider).selectedProvider;
    if (modelId == null || modelId.isEmpty) {
      return (isValid: false, message: 'No model selected for ${provider.displayName}. Go to Settings → Model.');
    }
    return (isValid: true, message: null);
  }

  Future<({bool isValid, String? message})> validateApiKey() async {
    final settings = ref.read(settingsProvider);
    final apiKey = await ref.read(settingsProvider.notifier).getApiKeyForProvider(settings.selectedProvider);
    if (apiKey == null || apiKey.isEmpty) {
      return (isValid: false, message: 'API key not configured for ${settings.selectedProvider.displayName}. Go to Settings → API Key.');
    }
    return (isValid: true, message: null);
  }

  void _pushHistory(CuratedPost content) {
    final next = List<String>.of(state.historyStack)..add(jsonEncode(content.toJson()));
    if (next.length > 20) next.removeAt(0);
    state = state.copyWith(historyStack: next);
  }

  bool undoLastRefinement() {
    if (state.historyStack.isEmpty) return false;
    final next = List<String>.of(state.historyStack);
    final jsonStr = next.removeLast();
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      state = state.copyWith(
        curatedPost: CuratedPost.fromJson(map),
        status: GenerateStatus.success,
        historyStack: next,
      );
    } catch (_) {
      state = state.copyWith(
        curatedPost: CuratedPost.fromMarkdownFallback(jsonStr),
        status: GenerateStatus.success,
        historyStack: next,
      );
    }
    return true;
  }

  void _addRecentInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    final next = List<String>.of(state.recentInputs)..remove(trimmed);
    next.insert(0, trimmed);
    if (next.length > 5) next.removeLast();
    state = state.copyWith(recentInputs: next);
  }

  Failure _mapError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('429') || s.contains('rate limit') || s.contains('quota') || s.contains('resource_exhausted')) {
      return const RateLimitFailure('Rate limit exceeded');
    }
    if (s.contains('401') || s.contains('403') || s.contains('unauthorized') || s.contains('invalid api key') || s.contains('permission')) {
      return const AuthFailure('Authentication failed');
    }
    if (s.contains('timeout') || s.contains('socketexception') || s.contains('failed host lookup')) {
      return const NetworkFailure('Network error');
    }
    return UnknownFailure(e.toString());
  }

  Future<void> generatePost(String input) async {
    final v = validateForGenerate(input);
    if (!v.isValid) {
      state = state.copyWith(status: GenerateStatus.error, errorMessage: v.message, validationMessage: v.message);
      return;
    }
    final apiCheck = await validateApiKey();
    if (!apiCheck.isValid) {
      state = state.copyWith(status: GenerateStatus.error, errorMessage: apiCheck.message, validationMessage: apiCheck.message);
      return;
    }

    state = state.copyWith(
      status: GenerateStatus.generating,
      step: GeneratingStep.prompting,
      clearCuratedPost: true,
      clearError: true,
      clearValidation: true,
      clearFallback: true,
      pendingInput: input.trim(),
      recentInputs: (() {
        _addRecentInput(input.trim());
        return null;
      })(),
    );
    // Ensure recentInputs updated via _addRecentInput already set above; re-apply
    _addRecentInput(input.trim());

    final stopwatch = Stopwatch()..start();
    final settings = ref.read(settingsProvider);
    final provider = settings.selectedProvider;
    final log = ref.read(logServiceProvider);

    try {
      dynamic contentToCurate = input.trim();
      String? sourceUrl;

      if (WebScraperService.isUrl(contentToCurate as String)) {
        state = state.copyWith(step: GeneratingStep.scraping);
        try {
          final article = await WebScraperService.extractArticleFromUrl(contentToCurate).timeout(const Duration(seconds: 10));
          contentToCurate = article;
          sourceUrl = article.url;
          if (article.text.trim().isEmpty) {
            log.warning('Scrape returned empty, falling back to raw input');
            contentToCurate = input.trim();
            sourceUrl = input.trim();
          }
        } on TimeoutException {
          throw Exception('URL extraction timed out. Please paste the article text manually.');
        }
        state = state.copyWith(step: GeneratingStep.prompting);
      }

      final modelId = ref.read(settingsProvider).selectedModel;
      if (modelId == null || modelId.isEmpty) throw Exception('No model selected.');

      final apiKey = await ref.read(settingsProvider.notifier).getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) throw Exception('API key not configured for ${provider.displayName}.');

      // Use repository/provider abstraction — falls back to CuratorFactory via apiClient
      final apiClient = ref.read(apiClientProvider);
      // For now, delegate to legacy CuratorFactory through repository layer (Phase A4)
      // This keeps notifier testable once ContentRepository is wired.

      // Temporary: import CuratorFactory directly (will be replaced by repository)
      // ignore: avoid_dynamic_calls
      final curatedPost = await _generateViaCurator(contentToCurate, modelId, apiKey, sourceUrl, provider, apiClient);
      state = state.copyWith(curatedPost: curatedPost);

      stopwatch.stop();
      final tokens = ((input.length + (curatedPost.rawMarkdown.length)) / 4).round();
      final usage = ref.read(usageServiceProvider);
      // ignore: unawaited_futures
      usage.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: modelId,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: tokens,
        isSuccess: true,
      ));
      log.info('Generated post successfully in ${stopwatch.elapsedMilliseconds}ms');
      state = state.copyWith(status: GenerateStatus.success, step: GeneratingStep.idle);
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification('Post Ready', 'Your AI-curated social media post has been generated successfully.');
      }
    } catch (e, st) {
      stopwatch.stop();
      final usage = ref.read(usageServiceProvider);
      // ignore: unawaited_futures
      usage.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: ref.read(settingsProvider).selectedModel,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));
      ref.read(logServiceProvider).error('Failed to generate post', e, st);
      final failure = _mapError(e);
      if (failure is RateLimitFailure) {
        state = state.copyWith(
          status: GenerateStatus.rateLimited,
          errorMessage: 'Rate limit exceeded for ${provider.displayName}. Try another provider.',
          suggestedFallbackProvider: _getNextProvider(provider),
          step: GeneratingStep.idle,
        );
      } else if (failure is AuthFailure) {
        state = state.copyWith(
          status: GenerateStatus.error,
          errorMessage: 'Authentication failed for ${provider.displayName}. Check your API key in Settings.',
          step: GeneratingStep.idle,
        );
      } else if (failure is NetworkFailure) {
        state = state.copyWith(
          status: GenerateStatus.error,
          errorMessage: 'Network error. Please check your connection and try again.',
          step: GeneratingStep.idle,
        );
      } else {
        final raw = e.toString();
        final clean = raw.startsWith('Exception:') ? raw.substring(10).trim() : raw;
        state = state.copyWith(
          status: GenerateStatus.error,
          errorMessage: clean.length > 220 ? '${clean.substring(0, 220)}…' : clean,
          step: GeneratingStep.idle,
        );
      }
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification('Generation Failed', 'There was an error generating your post.');
      }
    }
  }

  // Internal helper — will be replaced by ContentRepository in A4
  Future<CuratedPost> _generateViaCurator(dynamic content, String modelId, String apiKey, String? sourceUrl, AiProvider provider, dynamic apiClient) async {
    final curator = CuratorFactory.getCurator(provider);
    return curator.generateStructuredPost(content: content, modelId: modelId, apiKey: apiKey, sourceUrl: sourceUrl);
  }

  Future<void> refineContent(String instruction) async {
    final current = state.curatedPost;
    if (current == null) return;
    state = state.copyWith(status: GenerateStatus.generating, step: GeneratingStep.prompting, clearError: true, clearValidation: true);
    _pushHistory(current);

    final stopwatch = Stopwatch()..start();
    final provider = ref.read(settingsProvider).selectedProvider;
    try {
      final modelId = ref.read(settingsProvider).selectedModel;
      if (modelId == null || modelId.isEmpty) throw Exception('No model selected.');
      final apiKey = await ref.read(settingsProvider.notifier).getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) throw Exception('API key not configured.');

      final currentJson = jsonEncode(current.toJson());
      final refinementContent =
          'Arahan penambahbaikan: "$instruction".\nKekalkan sumber yang sama (${current.source.url ?? current.source.label}).\nJSON semasa:\n$currentJson\n\nKembalikan JSON dengan struktur yang sama (title, body, hashtags, source) — perbaiki title/body/hashtags mengikut arahan, jangan ubah source.url.';

      final apiClient = ref.read(apiClientProvider);
      final refined = await _generateViaCurator(refinementContent, modelId, apiKey, current.source.url, provider, apiClient);

      final merged = CuratedPost.fromJson({
        'title': refined.title.isEmpty ? current.title : refined.title,
        'body': refined.bodyMarkdown.isEmpty ? current.bodyMarkdown : refined.bodyMarkdown,
        'hashtags': refined.hashtags.isEmpty ? current.hashtags : refined.hashtags,
        'source': current.source.toJson(),
      });
      state = state.copyWith(curatedPost: merged);

      stopwatch.stop();
      final tokens = ((refinementContent.length + merged.rawMarkdown.length) / 4).round();
      final usage = ref.read(usageServiceProvider);
      // ignore: unawaited_futures
      usage.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: modelId,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: tokens,
        isSuccess: true,
      ));
      ref.read(logServiceProvider).info('Refined post successfully in ${stopwatch.elapsedMilliseconds}ms');
      state = state.copyWith(status: GenerateStatus.success, step: GeneratingStep.idle);
      if (_isBackgrounded) NotificationService().showGenerationCompleteNotification('Refinement Ready', 'Your refined social media post is ready.');
    } catch (e, st) {
      stopwatch.stop();
      final usage = ref.read(usageServiceProvider);
      // ignore: unawaited_futures
      usage.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: ref.read(settingsProvider).selectedModel,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));
      ref.read(logServiceProvider).error('Failed to refine post', e, st);
      final failure = _mapError(e);
      if (failure is RateLimitFailure) {
        state = state.copyWith(status: GenerateStatus.rateLimited, errorMessage: 'Rate limit exceeded for ${provider.displayName}.', suggestedFallbackProvider: _getNextProvider(provider), step: GeneratingStep.idle);
      } else if (failure is AuthFailure) {
        state = state.copyWith(status: GenerateStatus.error, errorMessage: 'Authentication failed for ${provider.displayName}. Check your API key in Settings.', step: GeneratingStep.idle);
      } else {
        final raw = e.toString();
        final clean = raw.startsWith('Exception:') ? raw.substring(10).trim() : raw;
        state = state.copyWith(status: GenerateStatus.error, errorMessage: clean.length > 220 ? '${clean.substring(0, 220)}…' : clean, step: GeneratingStep.idle);
      }
      if (_isBackgrounded) NotificationService().showGenerationCompleteNotification('Refinement Failed', 'There was an error refining your post.');
    }
  }

  void reset() {
    state = state.copyWith(
      status: GenerateStatus.idle,
      step: GeneratingStep.idle,
      clearCuratedPost: true,
      clearError: true,
      clearValidation: true,
      clearFallback: true,
    );
  }

  Future<void> extractTextFromImage(ImageSource source) async {
    final extractor = ref.read(visionExtractorProvider);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source);
      if (xfile != null) {
        state = state.copyWith(isExtractingImage: true);
        final text = await extractor.extractText(xfile.path);
        if (text.isNotEmpty) {
          setPendingInput(text);
        } else {
          state = state.copyWith(status: GenerateStatus.error, errorMessage: 'No text found in the image.');
        }
      }
    } catch (e) {
      state = state.copyWith(status: GenerateStatus.error, errorMessage: 'Failed to extract text: $e');
    } finally {
      state = state.copyWith(isExtractingImage: false);
    }
  }
}

final generateProvider = NotifierProvider<GenerateNotifier, GenerateState>(GenerateNotifier.new);
