import 'package:dio/dio.dart';

import '../../core/error/failures.dart';
import '../models/tavily_search.dart';

abstract class ISearchRepository {
  /// Legacy raw search. Kept so existing fakes/tests keep working; new code
  /// should use [search] which returns a typed [Result] and accepts a
  /// [CancelToken].
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  });

  /// Legacy raw extraction.
  Future<String> extractFromUrl(String url);

  /// Checks if a Tavily key is stored (non-empty only — use
  /// [testConnection] to validate it).
  Future<bool> isConfigured();

  /// Typed search with the full parameter set.
  Future<Result<TavilySearchResponse>> search(
    SearchOptions options, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await searchContext(
        query: options.query,
        maxResults: options.maxResults,
        includeAnswer: options.includeAnswer,
      );
      return ResultSuccess(response);
    } catch (e) {
      return ResultError(mapSearchException(e));
    }
  }

  /// Typed extraction. Implementations should surface `failed_results` and a
  /// missing `raw_content` as a [ParseFailure].
  Future<Result<String>> extract(
    String url, {
    CancelToken? cancelToken,
    String? query,
  }) async {
    try {
      return ResultSuccess(await extractFromUrl(url));
    } catch (e) {
      return ResultError(mapSearchException(e));
    }
  }

  /// Validates a key with a tiny search. Returns a specific message on
  /// failure so Settings can explain 401 vs plan-limit vs network.
  Future<SearchConnectionResult> testConnection({String? apiKey}) async {
    if (apiKey != null && apiKey.trim().isEmpty) {
      return const SearchConnectionResult.failure('API key is empty');
    }
    final result = await search(
      const SearchOptions(
        query: 'football',
        maxResults: 1,
        includeAnswer: false,
      ),
    );
    return result.fold(
      (response) => SearchConnectionResult.success(
        message: 'Connected',
        credits: response.credits,
      ),
      (failure) => SearchConnectionResult.failure(failure.message),
    );
  }
}

/// Maps repository exceptions to the app's sealed [Failure] hierarchy.
Failure mapSearchException(Object error) {
  if (error is Failure) return error;
  if (error is DioException) {
    final extra = error.requestOptions.extra;
    final isTavily =
        extra['provider'] == 'tavily' ||
        extra['search'] == true ||
        extra['extract'] == true;
    final status = error.response?.statusCode;
    final body = error.response?.data?.toString() ?? '';
    final short = body.length > 180 ? '${body.substring(0, 180)}…' : body;

    // Tavily has plan-specific status codes (432/433/434) that the generic
    // ErrorMappingInterceptor does not know about. They must win over its
    // cached `extra['failure']`, otherwise users see an opaque body dump.
    if (isTavily && status != null) {
      final tavilyFailure = _mapTavilyStatus(status, short, error.response);
      if (tavilyFailure != null) return tavilyFailure;
    }

    final mapped = extra['failure'];
    if (mapped is Failure) return mapped;
    switch (status) {
      case 401:
      case 403:
        return const AuthFailure(
          'Tavily rejected the API key (401). Check it in Settings.',
        );
      case 429:
        return RateLimitFailure(
          'Tavily rate limit reached. Try again shortly.',
          retryDelayMs: _retryAfterMs(error.response),
          providerName: 'tavily',
        );
      case 432:
        return const PaymentRequiredFailure(
          'Tavily plan limit reached. Upgrade your Tavily plan or wait for the next cycle.',
          providerName: 'tavily',
        );
      case 433:
        return const PaymentRequiredFailure(
          'Tavily Pay-As-You-Go limit reached. Add credits or raise the limit.',
          providerName: 'tavily',
        );
      case 434:
        return const NetworkFailure(
          'Tavily is at capacity right now. Try again in a moment.',
        );
      case 400:
      case 422:
        return ParseFailure('Tavily rejected the request: $short');
    }
    if (status != null && status >= 500) {
      return ServerFailure('Tavily server error ($status). Try again later.');
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure('Tavily request timed out.');
      case DioExceptionType.cancel:
        return const NetworkFailure('Tavily request cancelled.');
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'Could not reach Tavily. Check your connection.',
        );
      default:
        return NetworkFailure(
          'Tavily request failed: ${error.message ?? short}',
        );
    }
  }
  if (error is FormatException || error is TypeError) {
    return ParseFailure('Unexpected Tavily response: $error');
  }
  return UnknownFailure(error.toString());
}

Failure? _mapTavilyStatus(int status, String short, Response? response) {
  switch (status) {
    case 401:
    case 403:
      return const AuthFailure(
        'Tavily rejected the API key (401). Check it in Settings.',
      );
    case 429:
      return RateLimitFailure(
        'Tavily rate limit reached. Try again shortly.',
        retryDelayMs: _retryAfterMs(response),
        providerName: 'tavily',
      );
    case 432:
      return const PaymentRequiredFailure(
        'Tavily plan limit reached. Upgrade your Tavily plan or wait for the next cycle.',
        providerName: 'tavily',
      );
    case 433:
      return const PaymentRequiredFailure(
        'Tavily Pay-As-You-Go limit reached. Add credits or raise the limit.',
        providerName: 'tavily',
      );
    case 434:
      return const NetworkFailure(
        'Tavily is at capacity right now. Try again in a moment.',
      );
    case 400:
    case 422:
      return ParseFailure('Tavily rejected the request: $short');
    default:
      if (status >= 500) {
        return ServerFailure('Tavily server error ($status). Try again later.');
      }
      return null;
  }
}

int? _retryAfterMs(Response? response) {
  final raw = response?.headers.value('retry-after');
  if (raw == null) return null;
  final seconds = int.tryParse(raw.trim());
  return seconds == null ? null : seconds * 1000;
}
