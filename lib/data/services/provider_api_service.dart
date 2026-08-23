import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';

class ProviderApiException implements Exception {
  final String message;
  ProviderApiException(this.message);
  @override
  String toString() => message;
}

class ProviderApiService {
  /// Fetches available models for a given provider and API key.
  /// Throws [ProviderApiException] if the request fails or key is invalid.
  Future<List<String>> fetchModels(AiProvider provider, String apiKey) async {
    if (apiKey.isEmpty) throw ProviderApiException('API key is empty');

    try {
      return switch (provider) {
        AiProvider.gemini => await _fetchGeminiModels(apiKey),
        AiProvider.groq => await _fetchOpenAICompatibleModels(provider.baseUrl, apiKey, prefixFilter: ''),
        AiProvider.openRouter => await _fetchOpenAICompatibleModels(provider.baseUrl, apiKey, prefixFilter: ''),
        AiProvider.cerebras => await _fetchOpenAICompatibleModels(provider.baseUrl, apiKey, prefixFilter: ''),
      };
    } catch (e) {
      if (e is ProviderApiException) rethrow;
      throw ProviderApiException('Failed to connect to ${provider.displayName}: $e');
    }
  }

  Future<List<String>> _fetchGeminiModels(String apiKey) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw ProviderApiException('Gemini API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final models = data['models'] as List<dynamic>? ?? [];
    
    return models
        .map((m) => m['name'] as String)
        .where((name) => name.contains('gemini'))
        .map((name) => name.replaceFirst('models/', '')) // Clean up name
        .toList();
  }

  Future<List<String>> _fetchOpenAICompatibleModels(String baseUrl, String apiKey, {String prefixFilter = ''}) async {
    final url = Uri.parse('$baseUrl/models');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw ProviderApiException('API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final models = data['data'] as List<dynamic>? ?? [];

    return models
        .map((m) => m['id'] as String)
        .where((id) => id.startsWith(prefixFilter))
        .toList();
  }
}

