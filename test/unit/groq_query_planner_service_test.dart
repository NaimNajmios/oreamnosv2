import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/groq_query_planner_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/query_planner_quota_guard.dart';

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
        'retry-after': ['30'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<GroqQueryPlannerService> _service(
  _StubAdapter adapter, {
  String key = 'gsk-test-key',
  Map<String, Object> prefs = const {},
}) async {
  FlutterSecureStorage.setMockInitialValues({
    if (key.isNotEmpty) AppConstants.keyGroqApiKey: key,
  });
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final api = ApiClient();
  api.dio.httpClientAdapter = adapter;
  return GroqQueryPlannerService(
    api,
    PreferencesService(
      prefs: sharedPrefs,
      secureStorage: const FlutterSecureStorage(),
    ),
    QueryPlannerQuotaGuard(sharedPrefs),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('plans entities and queries from a Groq JSON response', () async {
    final adapter = _StubAdapter(200, {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': jsonEncode({
              'entities': ['Max Dowman', 'Arsenal'],
              'queries': [
                'Max Dowman Arsenal first professional contract',
                'Max Dowman 17th birthday deal',
              ],
            }),
          },
        },
      ],
    });
    final service = await _service(adapter);
    final longText = 'Max Dowman Arsenal contract. ${'filler ' * 500}ZZZ_END';

    final suggestion = await service.plan(text: longText);

    expect(suggestion, isNotNull);
    expect(suggestion!.entities, contains('Max Dowman'));
    expect(suggestion.queries.first, contains('Max Dowman Arsenal'));
    expect(suggestion.queries.length, 2);

    final request = adapter.requests.single;
    expect(request.path, contains('/chat/completions'));
    expect(request.headers['Authorization'], 'Bearer gsk-test-key');
    expect(request.extra['noRetry'], isTrue);
    final body = request.data as Map<String, dynamic>;
    expect(body['model'], AppConstants.groqPlannerModelId);
    expect(body['response_format'], {'type': 'json_object'});
    expect(body['temperature'], 0);
    final userText = (body['messages'] as List).last['content'] as String;
    expect(
      userText.length,
      lessThan(AppConstants.groqPlannerMaxInputChars + 60),
    );
    expect(userText, isNot(contains('ZZZ_END')));
  });

  test('429 skips the step without a retry', () async {
    final adapter = _StubAdapter(429, {
      'error': {'message': 'rate limited'},
    });
    final service = await _service(adapter);

    final suggestion = await service.plan(text: 'Max Dowman Arsenal contract');

    expect(suggestion, isNull);
    expect(adapter.requests, hasLength(1));
  });

  test('model-not-found falls back to heuristic', () async {
    final adapter = _StubAdapter(400, {
      'error': {'message': 'The model llama-3.1-8b-instant does not exist'},
    });
    final service = await _service(adapter);

    expect(await service.plan(text: 'Max Dowman Arsenal contract'), isNull);
  });

  test('malformed JSON is rejected', () async {
    final adapter = _StubAdapter(200, {
      'choices': [
        {
          'message': {'content': 'not json at all'},
        },
      ],
    });
    final service = await _service(adapter);

    expect(await service.plan(text: 'Max Dowman Arsenal contract'), isNull);
  });

  test('no Groq key skips without a network call', () async {
    final adapter = _StubAdapter(200, {'choices': []});
    final service = await _service(adapter, key: '');

    expect(await service.plan(text: 'Max Dowman Arsenal contract'), isNull);
    expect(adapter.requests, isEmpty);
  });

  test('planner counter is independent and caps calls', () async {
    final now = DateTime.now().toUtc();
    final date =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final adapter = _StubAdapter(200, {'choices': []});
    final service = await _service(
      adapter,
      prefs: {
        'query_planner_groq_count_$date': AppConstants.groqPlannerDailyCap,
      },
    );

    expect(await service.plan(text: 'Max Dowman Arsenal contract'), isNull);
    expect(adapter.requests, isEmpty);
  });
}
