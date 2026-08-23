import 'package:flutter/foundation.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';

enum GenerateState { idle, generating, success, error }

class GenerateViewModel extends ChangeNotifier {
  GenerateViewModel(this._settingsViewModel);

  final SettingsViewModel _settingsViewModel;

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

    try {
      String contentToCurate = input.trim();
      
      // Extract text if input is a URL
      if (WebScraperService.isUrl(contentToCurate)) {
        contentToCurate = await WebScraperService.extractTextFromUrl(contentToCurate);
      }
      final provider = _settingsViewModel.selectedProvider;
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

      _state = GenerateState.success;
    } catch (e) {
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
}

