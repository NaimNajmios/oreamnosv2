import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/repositories/tavily_search_repository.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/tavily_search.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body);

  final int status;
  final Object body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body is String ? body as String : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<TavilySearchRepository> _repo(_StubAdapter adapter) async {
  FlutterSecureStorage.setMockInitialValues({
    AppConstants.keyTavilyApiKey: 'tvly-test-key',
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient();
  api.dio.httpClientAdapter = adapter;
  return TavilySearchRepository(
    api,
    PreferencesService(
      prefs: prefs,
      secureStorage: const FlutterSecureStorage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TavilySearchRepository', () {
    test('sends Bearer auth and parses usage metadata', () async {
      final adapter = _StubAdapter(200, {
        'query': 'jdt selangor',
        'results': [
          {
            'title': 'JDT beat Selangor',
            'url': 'https://www.bbc.com/sport/1',
            'content': 'Johor Darul Ta\'zim won 2-1.',
            'score': 0.9,
            'published_date': '2026-11-27',
          },
        ],
        'usage': {'credits': 2},
        'request_id': 'req-1',
        'response_time': 0.4,
      });
      final repo = await _repo(adapter);

      final result = await repo.search(
        const SearchOptions(
          query: 'jdt selangor',
          topic: 'general',
          searchDepth: 'basic',
          maxResults: 4,
        ),
      );

      expect(result, isA<ResultSuccess<TavilySearchResponse>>());
      final data = result.dataOrNull!;
      expect(data.credits, 2);
      expect(data.requestId, 'req-1');
      expect(data.results.single.publishedDate, '2026-11-27');

      final request = adapter.requests.single;
      expect(request.headers['Authorization'], 'Bearer tvly-test-key');
      final body = request.data as Map<String, dynamic>;
      expect(body.containsKey('api_key'), isFalse);
      expect(body['query'], 'jdt selangor');
      expect(body['search_depth'], 'basic');
      expect(body['include_usage'], isTrue);
    });

    test('does not send country for news topic', () async {
      final adapter = _StubAdapter(200, {'results': []});
      final repo = await _repo(adapter);

      await repo.search(
        const SearchOptions(
          query: 'transfer news',
          topic: 'news',
          country: 'malaysia',
        ),
      );

      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body.containsKey('country'), isFalse);
    });

    test('401 maps to AuthFailure', () async {
      final adapter = _StubAdapter(401, {'detail': 'invalid key'});
      final repo = await _repo(adapter);

      final result = await repo.search(const SearchOptions(query: 'x'));

      expect(result, isA<ResultError<TavilySearchResponse>>());
      final failure = (result as ResultError<TavilySearchResponse>).failure;
      expect(failure, isA<AuthFailure>());
    });

    test('432 and 433 map to PaymentRequiredFailure', () async {
      for (final status in [432, 433]) {
        final adapter = _StubAdapter(status, {'detail': 'limit'});
        final repo = await _repo(adapter);

        final result = await repo.search(const SearchOptions(query: 'x'));

        final failure = (result as ResultError<TavilySearchResponse>).failure;
        expect(
          failure,
          isA<PaymentRequiredFailure>(),
          reason: 'status $status',
        );
      }
    });

    test('429 maps to RateLimitFailure with provider name', () async {
      final adapter = _StubAdapter(429, {'detail': 'slow down'});
      final repo = await _repo(adapter);

      final result = await repo.search(const SearchOptions(query: 'x'));

      final failure = (result as ResultError<TavilySearchResponse>).failure;
      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).providerName, 'tavily');
    });

    test('identical searches are served from the cache', () async {
      final adapter = _StubAdapter(200, {
        'results': [
          {
            'title': 'Arsenal',
            'url': 'https://example.com/a',
            'content': 'Arsenal news',
            'score': 0.8,
          },
        ],
      });
      final repo = await _repo(adapter);

      await repo.search(const SearchOptions(query: 'arsenal'));
      await repo.search(const SearchOptions(query: 'arsenal'));

      expect(adapter.requests, hasLength(1));
    });

    test('time-sensitive searches are not cached', () async {
      final adapter = _StubAdapter(200, {'results': []});
      final repo = await _repo(adapter);

      await repo.search(
        const SearchOptions(query: 'live score', timeRange: 'day'),
      );
      await repo.search(
        const SearchOptions(query: 'live score', timeRange: 'day'),
      );

      expect(adapter.requests, hasLength(2));
    });

    test('extract surfaces failed_results', () async {
      final adapter = _StubAdapter(200, {
        'results': [],
        'failed_results': [
          {'url': 'https://example.com', 'error': 'blocked'},
        ],
      });
      final repo = await _repo(adapter);

      final result = await repo.extract('https://example.com');

      expect(result, isA<ResultError<String>>());
      final failure = (result as ResultError<String>).failure;
      expect(failure, isA<ParseFailure>());
      expect(failure.message, contains('blocked'));
    });

    test('extract rejects a null raw_content', () async {
      final adapter = _StubAdapter(200, {
        'results': [
          {'url': 'https://example.com'},
        ],
      });
      final repo = await _repo(adapter);

      final result = await repo.extract('https://example.com');

      expect(result, isA<ResultError<String>>());
    });

    test('testConnection reports failure for a rejected key', () async {
      final adapter = _StubAdapter(401, {'detail': 'invalid key'});
      final repo = await _repo(adapter);

      final result = await repo.testConnection(apiKey: 'tvly-bad');

      expect(result.ok, isFalse);
      expect(result.message, contains('401'));
    });
  });
}
