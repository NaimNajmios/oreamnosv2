import 'package:uuid/uuid.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/domain/services/vision_extractor.dart';
import 'package:oreamnos/data/services/notification_service.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:flutter/widgets.dart'; // for AppLifecycleState

enum GenerateState { idle, generating, success, error, rateLimited }

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

  String? _generatedContent;
  String? get generatedContent => _generatedContent;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AiProvider? _suggestedFallbackProvider;
  AiProvider? get suggestedFallbackProvider => _suggestedFallbackProvider;

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
    } else if (_generatedContent != null) {
      // Just re-generate with the last successful input? Or just use the original pending input?
      // For simplicity, we just trigger generation with the pending input, which should be stored
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
    if (_generatedContent == null) return null;
    String content = _generatedContent!;

    // A simple heuristic for markdown structure (could be customized)
    // If showTitle is false, remove the first header if it exists
    if (!_showTitle) {
      content = content.replaceFirst(RegExp(r'^#+ [^\n]+\n+'), '');
    }

    // If showHashtags is false, remove lines starting with hashtags or the last paragraph full of hashtags
    if (!_showHashtags) {
      content = content.replaceAll(RegExp(r'\n+(#[^\s#]+ *)+$'), '');
    }

    // If showSource is false, remove lines like "Sumber:" or "Source:"
    if (!_showSource) {
      content = content.replaceAll(RegExp(r'\n+(Sumber|Source):[^\n]+$'), '');
    }

    return content.trim();
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
    if (input.trim().isEmpty) return;

    _state = GenerateState.generating;
    _errorMessage = null;
    _generatedContent = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final provider = _settingsViewModel.selectedProvider;

    try {
      String contentToCurate = input.trim();
      
      // Extract text if input is a URL
      if (WebScraperService.isUrl(contentToCurate)) {
        contentToCurate = await WebScraperService.extractTextFromUrl(contentToCurate);
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

      _generatedContent = await curator.generatePost(
        contentOrUrl: contentToCurate,
        modelId: modelId,
        apiKey: apiKey,
        tone: _settingsViewModel.toneMode,
        defaultHashtags: _settingsViewModel.autoAppendHashtags ? _settingsViewModel.defaultHashtags : '',
      );

      stopwatch.stop();
      final estimatedTokens = ((contentToCurate.length + (_generatedContent?.length ?? 0)) / 4).round();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: estimatedTokens,
        isSuccess: true,
      ));
      
      LogService().info('Generated post successfully in ${stopwatch.elapsedMilliseconds}ms');

      _state = GenerateState.success;
      
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
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));
      
      LogService().error('Failed to generate post', e, st);
      
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('429') || errStr.contains('rate limit') || errStr.contains('quota')) {
        _errorMessage = 'Rate limit exceeded for ${provider.displayName}.';
        _suggestedFallbackProvider = _getNextProvider(provider);
        _state = GenerateState.rateLimited;
      } else {
        _errorMessage = e.toString();
        _state = GenerateState.error;
      }
      
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Generation Failed',
          'There was an error generating your post.',
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> refineContent(String instruction) async {
    if (_generatedContent == null || _generatedContent!.isEmpty) return;

    _state = GenerateState.generating;
    _errorMessage = null;
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
      
      final refinementPrompt = 'Please refine the following social media post based on this instruction: "$instruction". Keep the original tone if not specified otherwise.\n\nPost:\n$_generatedContent';

      _generatedContent = await curator.generatePost(
        contentOrUrl: refinementPrompt,
        modelId: modelId,
        apiKey: apiKey,
        tone: _settingsViewModel.toneMode,
        defaultHashtags: '', // Do not auto-append hashtags again on refinement
      );

      stopwatch.stop();
      final estimatedTokens = ((refinementPrompt.length + (_generatedContent?.length ?? 0)) / 4).round();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: estimatedTokens,
        isSuccess: true,
      ));

      LogService().info('Refined post successfully in ${stopwatch.elapsedMilliseconds}ms');

      _state = GenerateState.success;
      
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
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));
      
      LogService().error('Failed to refine post', e, st);

      final errStr = e.toString().toLowerCase();
      if (errStr.contains('429') || errStr.contains('rate limit') || errStr.contains('quota')) {
        _errorMessage = 'Rate limit exceeded for ${provider.displayName}.';
        _suggestedFallbackProvider = _getNextProvider(provider);
        _state = GenerateState.rateLimited;
      } else {
        _errorMessage = e.toString();
        _state = GenerateState.error;
      }
      
      if (_isBackgrounded) {
        NotificationService().showGenerationCompleteNotification(
          'Refinement Failed',
          'There was an error refining your post.',
        );
      }
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _state = GenerateState.idle;
    _generatedContent = null;
    _errorMessage = null;
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

