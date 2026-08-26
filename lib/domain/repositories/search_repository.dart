import '../models/tavily_search.dart';

abstract class ISearchRepository {
  /// Searches the web for real-time context.
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  });

  /// Extracts clean text from a specific URL.
  Future<String> extractFromUrl(String url);
}
