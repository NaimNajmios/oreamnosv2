import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_insights_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

class _GraphAdapter implements HttpClientAdapter {
  _GraphAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic>? body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (body == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RawAdapter implements HttpClientAdapter {
  _RawAdapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      utf8.encode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FacebookInsightsService _service(HttpClientAdapter adapter) {
  final apiClient = ApiClient();
  apiClient.dio.httpClientAdapter = adapter;
  apiClient.dio.interceptors.clear();
  return FacebookInsightsService(apiClient);
}

const _token = 'EAAtestToken123';

Map<String, dynamic> _insights(List<Map<String, dynamic>> data) => {
  'insights': {'data': data},
};

void main() {
  group('FacebookInsightsService', () {
    test(
      'parses the current metrics and keeps the token out of the URL',
      () async {
        final adapter = _GraphAdapter(
          200,
          _insights([
            {
              'name': 'post_total_media_view_unique',
              'values': [
                {'value': 1200},
              ],
            },
            {
              'name': 'post_reactions_by_type_total',
              'values': [
                {
                  'value': {'like': 80, 'love': 4},
                },
              ],
            },
            {
              'name': 'post_activity_by_action_type',
              'values': [
                {
                  'value': {'post_reaction': 84, 'comment': 9, 'share': 3},
                },
              ],
            },
          ]),
        );
        final insights = await _service(adapter)
            .fetch(postId: '123_456', token: _token);

        expect(insights.uniqueViewers, 1200);
        expect(insights.reactions, 84);
        expect(insights.reactionsByType, {'like': 80, 'love': 4});
        expect(insights.activityByActionType, {
          'post_reaction': 84,
          'comment': 9,
          'share': 3,
        });
        // Retired metrics are never populated from a fresh response.
        expect(insights.impressions, isNull);
        expect(insights.clicks, isNull);
        expect(insights.hasAny, isTrue);

        final request = adapter.lastRequest!;
        expect(request.uri.toString(), contains('/v23.0/123_456'));
        expect(request.headers['Authorization'], contains(_token));
        expect(request.uri.queryParameters.values, isNot(contains(_token)));
        final fields = request.uri.queryParameters['fields']!;
        expect(fields, contains('post_total_media_view_unique'));
        expect(fields, contains('post_reactions_by_type_total'));
        expect(fields, contains('post_activity_by_action_type'));
        // Retired names must never be requested.
        expect(fields, isNot(contains('post_impressions')));
        expect(fields, isNot(contains('post_clicks')));
      },
    );

    test('missing metrics stay null, never zero', () async {
      final adapter = _GraphAdapter(
        200,
        _insights([
          {
            'name': 'post_total_media_view_unique',
            'values': [
              {'value': 5},
            ],
          },
        ]),
      );
      final insights = await _service(adapter)
          .fetch(postId: 'p', token: _token);
      expect(insights.uniqueViewers, 5);
      expect(insights.reactions, isNull);
      expect(insights.comments, isNull);
      expect(insights.shares, isNull);
      expect(insights.activityByActionType, isNull);
      expect(insights.hasAny, isTrue);
    });

    test('no insights block yields nulls and hasAny false', () async {
      final insights = await _service(_GraphAdapter(200, {'id': 'p'}))
          .fetch(postId: 'p', token: _token);
      expect(insights.hasAny, isFalse);
      expect(insights.uniqueViewers, isNull);
      expect(insights.reactions, isNull);
      expect(insights.clicks, isNull);
    });

    test('malformed metric values cannot crash the parser', () async {
      final insights = await _service(
        _GraphAdapter(
          200,
          _insights([
            {
              'name': 'post_total_media_view_unique',
              'values': [
                {'value': 'not-a-number'},
              ],
            },
            {
              'name': 'post_reactions_by_type_total',
              'values': [
                {'value': 'nope'},
              ],
            },
            {'name': 'post_activity_by_action_type', 'values': 'nope'},
          ]),
        ),
      ).fetch(postId: 'p', token: _token);
      expect(insights.uniqueViewers, isNull);
      expect(insights.reactions, isNull);
      expect(insights.activityByActionType, isNull);
    });

    test('empty post id or token throws insightsUnavailable', () async {
      final adapter = _GraphAdapter(200, {'id': 'p'});
      final service = _service(adapter);
      expect(
        () => service.fetch(postId: '', token: _token),
        throwsA(
          isA<FacebookApiException>().having(
            (e) => e.kind,
            'kind',
            FacebookApiErrorKind.insightsUnavailable,
          ),
        ),
      );
      expect(
        () => service.fetch(postId: 'p', token: '  '),
        throwsA(isA<FacebookApiException>()),
      );
      expect(adapter.lastRequest, isNull);
    });

    test('Graph 190 maps to expiredToken', () async {
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 190, 'message': 'Error validating access token'},
        }),
      );
      try {
        await service.fetch(postId: 'p', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.expiredToken);
        expect(e.needsReconnect, isTrue);
      }
    });

    test('Graph 400 on insights maps to insightsUnavailable', () async {
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 100, 'message': 'Unknown metric'},
        }),
      );
      try {
        await service.fetch(postId: 'p', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.insightsUnavailable);
        expect(e.message, contains('metric names may have changed'));
      }
    });

    test('HTML 200 response becomes unexpectedResponse', () async {
      final service = _service(
        _RawAdapter(200, '<!doctype html><html></html>'),
      );
      try {
        await service.fetch(postId: 'p', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.unexpectedResponse);
        expect(e.message, contains('web page'));
      }
    });
  });

  group('FacebookInsightsService.fetchEngagement', () {
    test('parses summary counts and keeps the token out of the URL', () async {
      final adapter = _GraphAdapter(200, {
        'reactions': {
          'data': [
            {'name': 'like', 'id': '1'},
          ],
          'summary': {'total_count': 42},
        },
        'comments': {
          'summary': {'total_count': 7},
        },
        'shares': {'count': 3},
      });
      final engagement = await _service(adapter)
          .fetchEngagement(postId: 'p', token: _token);

      expect(engagement.reactions, 42);
      expect(engagement.comments, 7);
      expect(engagement.shares, 3);
      // Engagement is separate from insights; no reach values here.
      expect(engagement.uniqueViewers, isNull);
      expect(engagement.hasAny, isTrue);

      final request = adapter.lastRequest!;
      expect(request.headers['Authorization'], contains(_token));
      expect(request.uri.queryParameters.values, isNot(contains(_token)));
      expect(request.uri.queryParameters['fields'], contains('reactions'));
      expect(request.uri.queryParameters['fields'], contains('comments'));
      expect(request.uri.queryParameters['fields'], contains('shares'));
    });

    test('missing summary fields stay null, never zero', () async {
      final engagement = await _service(_GraphAdapter(200, {'id': 'p'}))
          .fetchEngagement(postId: 'p', token: _token);

      expect(engagement.reactions, isNull);
      expect(engagement.comments, isNull);
      expect(engagement.shares, isNull);
      expect(engagement.hasAny, isFalse);
    });

    test('empty post id or token throws insightsUnavailable', () async {
      final adapter = _GraphAdapter(200, {'id': 'p'});
      final service = _service(adapter);
      expect(
        () => service.fetchEngagement(postId: '', token: _token),
        throwsA(
          isA<FacebookApiException>().having(
            (e) => e.kind,
            'kind',
            FacebookApiErrorKind.insightsUnavailable,
          ),
        ),
      );
      expect(
        () => service.fetchEngagement(postId: 'p', token: ' '),
        throwsA(isA<FacebookApiException>()),
      );
      expect(adapter.lastRequest, isNull);
    });

    test('Graph 190 maps to expiredToken', () async {
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 190, 'message': 'Error validating access token'},
        }),
      );
      try {
        await service.fetchEngagement(postId: 'p', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.expiredToken);
      }
    });
  });
}
