import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/domain/services/vision_extractor.dart';
import 'package:oreamnos/data/services/notification_service.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:flutter/widgets.dart'; // for AppLifecycleState

enum GenerateState { idle, generating, success, error, rateLimited }

enum GeneratingStep { idle, scraping, prompting }

class ValidationResult {
  final bool isValid;
  final String? message;
  const ValidationResult.valid() : isValid = true, message = null;
  const ValidationResult.invalid(this.message) : isValid = false;
}

class GenerateViewModel extends ChangeNotifier with WidgetsBindingObserver {
  GenerateViewModel(
    this._settingsViewModel, 
    this._usageService,
    [this._visionExtractor]
  ) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isBackgrounded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackgrounded = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
  }

  final SettingsViewModel _settingsViewModel;
  final UsageService _usageService;
  final IVisionExtractor? _visionExtractor;

  GenerateState _state = GenerateState.idle;
  GenerateState get state => _state;

  GeneratingStep _generatingStep = GeneratingStep.idle;
  GeneratingStep get generatingStep => _generatingStep;

  CuratedPost? _curatedPost;
  CuratedPost? get curatedPost => _curatedPost;

  // Compat: some screens still expect String
  String? get generatedContent => _curatedPost?.rawMarkdown;
  // For undo/history we store serialized CuratedPost
  // ignore: unused_field
  String? _legacyGeneratedContentForCompat;

  // Undo history for refinements — store serialized CuratedPost
  final List<String> _historyStack = [];
  bool get canUndo => _historyStack.isNotEmpty;

  // Recent inputs (kept in memory, persisted via PreferencesService draft)
  final List<String> _recentInputs = [];
  List<String> get recentInputs => List.unmodifiable(_recentInputs);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AiProvider? _suggestedFallbackProvider;
  AiProvider? get suggestedFallbackProvider => _suggestedFallbackProvider;

  String? _validationMessage;
  String? get validationMessage => _validationMessage;

  AiProvider _getNextProvider(AiProvider current) {
    switch (current) {
      case AiProvider.gemini: return AiProvider.groq;
      case AiProvider.groq: return AiProvider.openRouter;
      case AiProvider.openRouter: return AiProvider.cerebras;
      case AiProvider.cerebras: return AiProvider.gemini;
    }
  }

  Future<void> retryWithProvider(AiProvider provider) async {
    await _settingsViewModel.setSelectedProvider(provider);
    if (_pendingInput != null) {
      await generatePost(_pendingInput!);
    }
  }

  String? _pendingInput;
  String? get pendingInput => _pendingInput;

  // Dynamic Output Toggles
  bool _showTitle = true;
  bool get showTitle => _showTitle;

  bool _showHashtags = true;
  bool get showHashtags => _showHashtags;

  bool _showSource = true;
  bool get showSource => _showSource;

  void toggleTitle() {
    _showTitle = !_showTitle;
    notifyListeners();
  }

  void toggleHashtags() {
    _showHashtags = !_showHashtags;
    notifyListeners();
  }

  void toggleSource() {
    _showSource = !_showSource;
    notifyListeners();
  }

  String? get formattedContent {
    if (_curatedPost == null) return null;
    return _curatedPost!.toMarkdownFiltered(showTitle: _showTitle, showHashtags: _showHashtags, showSource: _showSource);
  }

  // For reading mode / card generator that needs body only
  String? get formattedBody => _curatedPost?.bodyMarkdown;
  SourceAttribution? get sourceAttribution => _curatedPost?.source;

  ValidationResult validateForGenerate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult.invalid('Please enter news text or a URL.');
    }
    if (trimmed.length > 8000) {
      return const ValidationResult.invalid('Input too long (max 8000 characters). Please shorten or paste a URL.');
    }
    final modelId = _settingsViewModel.selectedModel;
    if (modelId == null || modelId.isEmpty) {
      return ValidationResult.invalid('No model selected for $providerDisplayName. Go to Settings → Model.');
    }
    return const ValidationResult.valid();
  }

  String get providerDisplayName => _settingsViewModel.selectedProvider.displayName;

  Future<ValidationResult> validateApiKey() async {
    final provider = _settingsViewModel.selectedProvider;
    final apiKey = await _settingsViewModel.getApiKeyForProvider(provider);
    if (apiKey == null || apiKey.isEmpty) {
      return ValidationResult.invalid('API key not configured for ${provider.displayName}. Go to Settings → API Key.');
    }
    return const ValidationResult.valid();
  }

  void _pushHistory(CuratedPost content) {
    _historyStack.add(jsonEncode(content.toJson()));
    if (_historyStack.length > 20) _historyStack.removeAt(0);
  }

  bool undoLastRefinement() {
    if (_historyStack.isEmpty) return false;
    final jsonStr = _historyStack.removeLast();
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _curatedPost = CuratedPost.fromJson(map);
    } catch (_) {
      // fallback: treat as legacy markdown
      _curatedPost = CuratedPost.fromMarkdownFallback(jsonStr);
    }
    _legacyGeneratedContentForCompat = _curatedPost?.rawMarkdown;
    _state = GenerateState.success;
    notifyListeners();
    return true;
  }

  void _addRecentInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    _recentInputs.remove(trimmed);
    _recentInputs.insert(0, trimmed);
    if (_recentInputs.length > 5) _recentInputs.removeLast();
  }

  void setPendingInput(String input) {
    _pendingInput = input;
    notifyListeners();
  }

  void clearPendingInput() {
    _pendingInput = null;
    notifyListeners();
  }

  Future<void> generatePost(String input) async {
    final v = validateForGenerate(input);
    if (!v.isValid) {
      _errorMessage = v.message;
      _validationMessage = v.message;
      _state = GenerateState.error;
      notifyListeners();
      return;
    }
    final apiCheck = await validateApiKey();
    if (!apiCheck.isValid) {
      _errorMessage = apiCheck.message;
      _validationMessage = apiCheck.message;
      _state = GenerateState.error;
      notifyListeners();
      return;
    }

    _state = GenerateState.generating;
    _generatingStep = GeneratingStep.prompting;
    _errorMessage = null;
    _validationMessage = null;
    _curatedPost = null;
    _legacyGeneratedContentForCompat = null;
    _suggestedFallbackProvider = null;
    _pendingInput = input.trim();
    _addRecentInput(_pendingInput!);
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final provider = _settingsViewModel.selectedProvider;

    try {
      dynamic contentToCurate = _pendingInput!.trim();
      String? sourceUrl;
      
      if (WebScraperService.isUrl(contentToCurate as String)) {
        _generatingStep = GeneratingStep.scraping;
        notifyListeners();
        try {
          final article = await WebScraperService.extractArticleFromUrl(contentToCurate).timeout(const Duration(seconds: 10));
          contentToCurate = article;
          sourceUrl = article.url;
          if (article.text.trim().isEmpty) {
            LogService().warning('Scrape returned empty, falling back to raw input');
            contentToCurate = _pendingInput!;
            sourceUrl = _pendingInput;
          }
        } on TimeoutException {
          throw Exception('URL extraction timed out. Please paste the article text manually.');
        }
        _generatingStep = GeneratingStep.prompting;
        notifyListeners();
      }
      
      final modelId = _settingsViewModel.selectedModel;
      if (modelId == null || modelId.isEmpty) {
        throw Exception('No model selected. Please go to Settings to select a model.');
      }

      final apiKey = await _settingsViewModel.getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured for ${provider.displayName}.');
      }

      final curator = CuratorFactory.getCurator(provider);

      _curatedPost = await curator.generateStructuredPost(
        content: contentToCurate,
        modelId: modelId,
        apiKey: apiKey,
        sourceUrl: sourceUrl,
      );
      _legacyGeneratedContentForCompat = _curatedPost!.rawMarkdown;

      stopwatch.stop();
      final estimatedTokens = ((input.length + (_curatedPost?.rawMarkdown.length ?? 0)) / 4).round();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: modelId,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: estimatedTokens,
        isSuccess: true,
      ));
      
      LogService().info('Generated post successfully in ${stopwatch.elapsedMilliseconds}ms');

      _state = GenerateState.success;
      _generatingStep = GeneratingStep.idle;
      
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Post Ready',
          'Your AI-curated social media post has been generated successfully.',
        );
      }
    } catch (e, st) {
      stopwatch.stop();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: _settingsViewModel.selectedModel,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));
      
      LogService().error('Failed to generate post', e, st);
      
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('429') || errStr.contains('rate limit') || errStr.contains('quota') || errStr.contains('resource_exhausted')) {
        _errorMessage = 'Rate limit exceeded for ${provider.displayName}. Try another provider.';
        _suggestedFallbackProvider = _getNextProvider(provider);
        _state = GenerateState.rateLimited;
      } else if (errStr.contains('401') || errStr.contains('403') || errStr.contains('unauthorized') || errStr.contains('invalid api key') || errStr.contains('permission')) {
        _errorMessage = 'Authentication failed for ${provider.displayName}. Check your API key in Settings.';
        _state = GenerateState.error;
      } else if (errStr.contains('timeout') || errStr.contains('socketexception') || errStr.contains('failed host lookup')) {
        _errorMessage = 'Network error. Please check your connection and try again.';
        _state = GenerateState.error;
      } else {
        final raw = e.toString();
        final clean = raw.startsWith('Exception:') ? raw.substring(10).trim() : raw;
        _errorMessage = clean.length > 220 ? '${clean.substring(0, 220)}…' : clean;
        _state = GenerateState.error;
      }
      
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Generation Failed',
          'There was an error generating your post.',
        );
      }
      if (_state != GenerateState.generating) {
        _generatingStep = GeneratingStep.idle;
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> refineContent(String instruction) async {
    if (_curatedPost == null) return;

    _state = GenerateState.generating;
    _generatingStep = GeneratingStep.prompting;
    _errorMessage = null;
    _validationMessage = null;
    _pushHistory(_curatedPost!);
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final provider = _settingsViewModel.selectedProvider;

    try {
      final modelId = _settingsViewModel.selectedModel;
      if (modelId == null || modelId.isEmpty) {
        throw Exception('No model selected. Please go to Settings to select a model.');
      }

      final apiKey = await _settingsViewModel.getApiKeyForProvider(provider);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured for ${provider.displayName}.');
      }

      final curator = CuratorFactory.getCurator(provider);
      
      // Structured refinement: keep source, refine title/body
      final currentJson = jsonEncode(_curatedPost!.toJson());
      final refinementContent = 'Arahan penambahbaikan: "$instruction".\n'
          'Kekalkan sumber yang sama (${_curatedPost!.source.url ?? _curatedPost!.source.label}).\n'
          'JSON semasa:\n$currentJson\n\n'
          'Kembalikan JSON dengan struktur yang sama (title, body, hashtags, source) — perbaiki title/body/hashtags mengikut arahan, jangan ubah source.url.';

      final refined = await curator.generateStructuredPost(
        content: refinementContent,
        modelId: modelId,
        apiKey: apiKey,
        sourceUrl: _curatedPost!.source.url,
      );

      // Merge: if refined title empty, keep old
      _curatedPost = CuratedPost(
        title: refined.title.isEmpty ? _curatedPost!.title : refined.title,
        bodyMarkdown: refined.bodyMarkdown.isEmpty ? _curatedPost!.bodyMarkdown : refined.bodyMarkdown,
        hashtags: refined.hashtags.isEmpty ? _curatedPost!.hashtags : refined.hashtags,
        source: _curatedPost!.source, // never change source on refinement
        rawMarkdown: '', // will be rebuilt
      );
      // Rebuild rawMarkdown via fromJson logic
      _curatedPost = CuratedPost.fromJson({
        'title': _curatedPost!.title,
        'body': _curatedPost!.bodyMarkdown,
        'hashtags': _curatedPost!.hashtags,
        'source': _curatedPost!.source.toJson(),
      });
      _legacyGeneratedContentForCompat = _curatedPost!.rawMarkdown;

      stopwatch.stop();
      final estimatedTokens = ((refinementContent.length + (_curatedPost?.rawMarkdown.length ?? 0)) / 4).round();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: modelId,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: estimatedTokens,
        isSuccess: true,
      ));

      LogService().info('Refined post successfully in ${stopwatch.elapsedMilliseconds}ms');

      _state = GenerateState.success;
      _generatingStep = GeneratingStep.idle;
      
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Refinement Ready',
          'Your refined social media post is ready.',
        );
      }
    } catch (e, st) {
      stopwatch.stop();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        modelName: _settingsViewModel.selectedModel,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));
      
      LogService().error('Failed to refine post', e, st);

      final errStr = e.toString().toLowerCase();
      if (errStr.contains('429') || errStr.contains('rate limit') || errStr.contains('quota') || errStr.contains('resource_exhausted')) {
        _errorMessage = 'Rate limit exceeded for ${provider.displayName}.';
        _suggestedFallbackProvider = _getNextProvider(provider);
        _state = GenerateState.rateLimited;
      } else if (errStr.contains('401') || errStr.contains('403') || errStr.contains('unauthorized') || errStr.contains('invalid api key')) {
        _errorMessage = 'Authentication failed for ${provider.displayName}. Check your API key in Settings.';
        _state = GenerateState.error;
      } else {
        final raw = e.toString();
        final clean = raw.startsWith('Exception:') ? raw.substring(10).trim() : raw;
        _errorMessage = clean.length > 220 ? '${clean.substring(0, 220)}…' : clean;
        _state = GenerateState.error;
      }
      
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Refinement Failed',
          'There was an error refining your post.',
        );
      }
      if (_state != GenerateState.generating) {
        _generatingStep = GeneratingStep.idle;
      }
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _state = GenerateState.idle;
    _generatingStep = GeneratingStep.idle;
    _curatedPost = null;
    _legacyGeneratedContentForCompat = null;
    _errorMessage = null;
    _validationMessage = null;
    _suggestedFallbackProvider = null;
    notifyListeners();
  }

  bool _isExtractingImage = false;
  bool get isExtractingImage => _isExtractingImage;

  Future<void> extractTextFromImage(ImageSource source) async {
    if (_visionExtractor == null) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        _isExtractingImage = true;
        notifyListeners();
        
        final extractedText = await _visionExtractor.extractText(image.path);
        
        if (extractedText.isNotEmpty) {
          setPendingInput(extractedText);
        } else {
          _errorMessage = "No text found in the image.";
          _state = GenerateState.error;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to extract text: $e';
      _state = GenerateState.error;
    } finally {
      _isExtractingImage = false;
      notifyListeners();
    }
  }
}
