import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/error/failures.dart';
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

  /// Lightweight key check mirroring Android `DefaultConnectionTester`:
  /// sends a tiny probe generation and returns true when the provider
  /// answers without auth/rate-limit errors.
  Future<bool> testConnection(AiProvider provider, String apiKey) async {
    if (apiKey.isEmpty) return false;
    try {
      final models = await fetchModels(provider, apiKey);
      return models.isNotEmpty;
    } on ProviderApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

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
      throw ProviderApiException(_friendlyConnectMessage(provider, e));
    }
  }

  /// Prefers the already-mapped `Failure` message attached by
  /// `ErrorMappingInterceptor` over the raw `DioException` dump, so dialogs
  /// show human text instead of `DioException [bad response]: …`.
  static String _friendlyConnectMessage(AiProvider provider, Object e) {
    if (e is DioException) {
      final failure = e.requestOptions.extra['failure'];
      if (failure is Failure) return failure.message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Could not reach ${provider.displayName}. Check your connection and try again.';
      }
    }
    final flat = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    final short = flat.length <= 220 ? flat : '${flat.substring(0, 220)}…';
    return 'Failed to connect to ${provider.displayName}: $short';
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
          return AiModel(
            id: id,
            isFree: false,
          ); // No dynamic pricing from Gemini API yet
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

    return modelsData
        .map((m) {
          final id = m['id'] as String;
          bool isFree = false;
          if (m['pricing'] != null) {
            final pricing = m['pricing'];
            final promptCost = pricing['prompt'];
            final completionCost = pricing['completion'];
            if ((promptCost == "0" || promptCost == 0 || promptCost == "0.0") &&
                (completionCost == "0" ||
                    completionCost == 0 ||
                    completionCost == "0.0")) {
              isFree = true;
            }
          }
          return AiModel(
            id: id,
            isFree: isFree,
            supportsVision: _supportsVision(m),
          );
        })
        .where((m) => m.id.startsWith(prefixFilter))
        .toList();
  }

  /// Heuristic for OpenAI-compatible `/models` entries: true when the entry
  /// advertises image input (OpenRouter `architecture.modality`) or the id
  /// names a known vision family (scout/vision/vl/qwen2-vl).
  static bool _supportsVision(dynamic m) {
    try {
      if (m is Map) {
        final arch = m['architecture'];
        if (arch is Map) {
          final modality = (arch['modality'] ?? '').toString().toLowerCase();
          final inputModalities = arch['input_modalities'];
          if (modality.contains('image') ||
              (inputModalities is List &&
                  inputModalities
                      .map((e) => e.toString().toLowerCase())
                      .any((e) => e.contains('image')))) {
            return true;
          }
        }
      }
    } catch (_) {}
    final id = (m is Map ? (m['id'] ?? '').toString() : '').toLowerCase();
    return id.contains('vision') ||
        id.contains('scout') ||
        id.contains('-vl') ||
        id.contains('qwen2-vl') ||
        id.contains('llama-3.2');
  }

  static bool _isZeroCost(dynamic pricing) {
    if (pricing is! Map) return false;
    bool zero(v) => v == 0 || v == '0' || v == '0.0';
    return zero(pricing['prompt']) && zero(pricing['completion']);
  }

  /// Auto-discovers free vision models on OpenRouter at runtime so the
  /// vision chain self-heals when the free lineup rotates.
  /// Returns model ids ending in `:free` with image input capability.
  Future<List<String>> fetchFreeVisionModels(String apiKey) async {
    final response = await _client.get<dynamic>(
      'https://openrouter.ai/api/v1/models',
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
    final raw = data is Map && data['data'] is List
        ? data['data'] as List
        : const [];
    final out = <String>[];
    for (final m in raw) {
      if (m is! Map) continue;
      final id = (m['id'] ?? '').toString();
      if (!id.endsWith(':free')) continue;
      if (!_supportsVision(m)) continue;
      if (m.containsKey('pricing') && !_isZeroCost(m['pricing'])) continue;
      out.add(id);
    }
    return out;
  }
}
