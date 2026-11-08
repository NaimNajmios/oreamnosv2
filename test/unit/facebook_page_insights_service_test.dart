import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_page_insights_service.dart';
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

FacebookPageInsightsService _service(HttpClientAdapter adapter) {
  final apiClient = ApiClient();
  apiClient.dio.httpClientAdapter = adapter;
  apiClient.dio.interceptors.clear();
  return FacebookPageInsightsService(apiClient);
}

const _token = 'EAAtestToken123';

void main() {
  group('FacebookPageInsightsService', () {
    test('merges per-day metrics and keeps the token out of the URL', () async {
      final adapter = _GraphAdapter(200, {
        'data': [
          {
            'name': 'page_media_view',
            'values': [
              {'value': 100, 'end_time': '2026-11-06T08:00:00+0000'},
              {'value': 120, 'end_time': '2026-11-07T08:00:00+0000'},
            ],
          },
          {
            'name': 'page_post_engagements',
            'values': [
              {'value': 10, 'end_time': '2026-11-06T08:00:00+0000'},
              {'value': 12, 'end_time': '2026-11-07T08:00:00+0000'},
            ],
          },
          {
            'name': 'page_follows',
            'values': [
              {'value': 300, 'end_time': '2026-11-07T08:00:00+0000'},
            ],
          },
        ],
      });

      final insights = await _service(adapter)
          .fetch(pageId: 'page-1', token: _token, days: 7);

      expect(insights.points, hasLength(2));
      expect(insights.hasMediaViews, isTrue);
      expect(insights.hasFollows, isTrue);
      expect(insights.hasEngagements, isTrue);
      expect(insights.totalMediaViews, 220);
      expect(insights.totalEngagements, 22);
      expect(insights.totalFollows, 300);
      expect(insights.hasAny, isTrue);

      final request = adapter.lastRequest!;
      expect(request.uri.toString(), contains('/v23.0/page-1/insights'));
      expect(request.headers['Authorization'], contains(_token));
      expect(request.uri.queryParameters.values, isNot(contains(_token)));
      final metric = request.uri.queryParameters['metric']!;
      expect(metric, contains('page_media_view'));
      expect(metric, contains('page_follows'));
      expect(metric, contains('page_post_engagements'));
    });

    test('a missing metric stays null and never drags others down', () async {
      final insights = await _service(
        _GraphAdapter(200, {
          'data': [
            {
              'name': 'page_media_view',
              'values': [
                {'value': 5, 'end_time': '2026-11-07T08:00:00+0000'},
              ],
            },
          ],
        }),
      ).fetch(pageId: 'page-1', token: _token);

      expect(insights.totalMediaViews, 5);
      expect(insights.totalFollows, isNull);
      expect(insights.totalEngagements, isNull);
      expect(insights.hasFollows, isFalse);
    });

    test('empty data returns an empty snapshot', () async {
      final insights = await _service(_GraphAdapter(200, {'data': <Object>[]}))
          .fetch(pageId: 'page-1', token: _token);

      expect(insights.points, isEmpty);
      expect(insights.hasAny, isFalse);
    });

    test('permission error explains required scopes', () async {
      final service = _service(
        _GraphAdapter(403, {
          'error': {'code': 200, 'message': 'Permissions error'},
        }),
      );

      try {
        await service.fetch(pageId: 'page-1', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.permission);
        expect(e.message, contains('read_insights'));
      }
    });

    test('empty page id throws permission before any request', () async {
      final adapter = _GraphAdapter(200, {'data': <Object>[]});
      final service = _service(adapter);

      expect(
        () => service.fetch(pageId: '', token: _token),
        throwsA(
          isA<FacebookApiException>().having(
            (e) => e.kind,
            'kind',
            FacebookApiErrorKind.permission,
          ),
        ),
      );
      expect(adapter.lastRequest, isNull);
    });
  });
}
