import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../models/ai_model.dart';
import '../models/ai_provider.dart';

class ProviderApiException implements Exception {
  final String message;
  ProviderApiException(this.message);
  @override
  String toString() => message;
}

@lazySingleton
class ProviderApiService {
  ProviderApiService([ApiClient? client])
    : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  /// Fetches available models for a given provider and API key.
  /// Throws [ProviderApiException] if the request fails or key is invalid.
  Future<List<AiModel>> fetchModels(AiProvider provider, String apiKey) async {
    if (apiKey.isEmpty) throw ProviderApiException('API key is empty');

    try {
      return switch (provider) {
        AiProvider.gemini => await _fetchGeminiModels(apiKey),
        AiProvider.groq => await _fetchOpenAICompatibleModels(
          provider.baseUrl,
          apiKey,
          prefixFilter: '',
        ),
        AiProvider.openRouter => await _fetchOpenAICompatibleModels(
          provider.baseUrl,
          apiKey,
          prefixFilter: '',
        ),
        AiProvider.cerebras => await _fetchOpenAICompatibleModels(
          provider.baseUrl,
          apiKey,
          prefixFilter: '',
        ),
      };
    } catch (e) {
      if (e is ProviderApiException) rethrow;
      throw ProviderApiException(
        'Failed to connect to ${provider.displayName}: $e',
      );
    }
  }

  Future<List<AiModel>> _fetchGeminiModels(String apiKey) async {
    final response = await _client.get<dynamic>(
      'https://generativelanguage.googleapis.com/v1beta/models',
      queryParameters: {'key': apiKey},
      options: Options(
        extra: {'provider': 'gemini'},
        responseType: ResponseType.json,
      ),
    );
    if (response.statusCode != 200) {
      throw ProviderApiException(
        'Gemini API Error: ${response.statusCode} - ${response.data}',
      );
    }
    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    final models = data['models'] as List<dynamic>? ?? [];

    return models
        .map((m) => m['name'] as String)
        .where((name) => name.contains('gemini'))
        .map((name) {
          final id = name.replaceFirst('models/', '');
          return AiModel(id: id, isFree: false); // No dynamic pricing from Gemini API yet
        })
        .toList();
  }

  Future<List<AiModel>> _fetchOpenAICompatibleModels(
    String baseUrl,
    String apiKey, {
    String prefixFilter = '',
  }) async {
    final response = await _client.get<dynamic>(
      '$baseUrl/models',
      options: Options(
        extra: {'apiKey': apiKey, 'provider': 'openai'},
        responseType: ResponseType.json,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (response.statusCode != 200) {
      throw ProviderApiException(
        'API Error: ${response.statusCode} - ${response.data}',
      );
    }
    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    final modelsData = data['data'] as List<dynamic>? ?? [];

    return modelsData.map((m) {
      final id = m['id'] as String;
      bool isFree = false;
      if (m['pricing'] != null) {
        final pricing = m['pricing'];
        final promptCost = pricing['prompt'];
        final completionCost = pricing['completion'];
        if ((promptCost == "0" || promptCost == 0 || promptCost == "0.0") &&
            (completionCost == "0" || completionCost == 0 || completionCost == "0.0")) {
          isFree = true;
        }
      }
      return AiModel(id: id, isFree: isFree);
    }).where((m) => m.id.startsWith(prefixFilter)).toList();
  }
}
