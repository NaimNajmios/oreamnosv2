import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/domain/services/vision_extractor.dart';

enum GenerateState { idle, generating, success, error }

class GenerateViewModel extends ChangeNotifier {
  GenerateViewModel(
    this._settingsViewModel, 
    this._usageService,
    [this._visionExtractor]
  );

  final SettingsViewModel _settingsViewModel;
  final UsageService _usageService;
  final IVisionExtractor? _visionExtractor;

  GenerateState _state = GenerateState.idle;
  GenerateState get state => _state;

  String? _generatedContent;
  String? get generatedContent => _generatedContent;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _pendingInput;
  String? get pendingInput => _pendingInput;

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

      _state = GenerateState.success;
    } catch (e) {
      stopwatch.stop();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));
      
      _errorMessage = e.toString();
      _state = GenerateState.error;
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

      _state = GenerateState.success;
    } catch (e) {
      stopwatch.stop();
      _usageService.logUsage(UsageLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        providerId: provider.name,
        latencyMs: stopwatch.elapsedMilliseconds,
        estimatedTokens: 0,
        isSuccess: false,
      ));

      _errorMessage = e.toString();
      _state = GenerateState.error;
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

