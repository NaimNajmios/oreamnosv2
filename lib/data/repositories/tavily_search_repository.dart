import 'package:injectable/injectable.dart';

import '../../domain/models/tavily_search.dart';
import '../../domain/repositories/search_repository.dart';
import '../services/preferences_service.dart';
import '../../core/network/api_client.dart';

@LazySingleton(as: ISearchRepository)
class TavilySearchRepository implements ISearchRepository {
  TavilySearchRepository(this._apiClient, this._prefs);

  final ApiClient _apiClient;
  final PreferencesService _prefs;
  static const _baseUrl = 'https://api.tavily.com';

  Future<String> _getApiKey() async {
    final key = await _prefs.getTavilyApiKey();
    if (key == null || key.isEmpty) {
      throw Exception('Tavily API Key is not configured.');
    }
    return key;
  }

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) async {
    final apiKey = await _getApiKey();
    final response = await _apiClient.post(
      '$_baseUrl/search',
      data: {
        'api_key': apiKey,
        'query': query,
        'search_depth': 'advanced',
        'include_answer': includeAnswer,
        'max_results': maxResults,
        'topic': 'news',
      },
    );
    return TavilySearchResponse.fromJson(response.data);
  }

  @override
  Future<String> extractFromUrl(String url) async {
    final apiKey = await _getApiKey();
    final response = await _apiClient.post(
      '$_baseUrl/extract',
      data: {
        'api_key': apiKey,
        'urls': [url],
      },
    );
    final results = response.data['results'] as List;
    if (results.isEmpty) throw Exception('Failed to extract URL');
    return results[0]['raw_content'] as String;
  }
}
