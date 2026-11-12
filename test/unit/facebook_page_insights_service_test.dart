import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_page_insights_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

class _GraphReply {
  const _GraphReply(this.status, this.body);

  final int status;
  final Map<String, dynamic>? body;
}

class _GraphAdapter implements HttpClientAdapter {
  _GraphAdapter(this.status, this.body, {this.byMetric});

  final int status;
  final Map<String, dynamic>? body;
  final Map<String, _GraphReply>? byMetric;
  final requests = <RequestOptions>[];

  RequestOptions? get lastRequest => requests.isEmpty ? null : requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final metric = options.uri.queryParameters['metric'] ?? '';
    final reply = byMetric?[metric];
    final responseStatus = reply?.status ?? status;
    final responseBody = reply?.body ?? body;
    if (responseBody == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(responseBody)),
      responseStatus,
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

Map<String, dynamic> _ok(List<Map<String, dynamic>> rows) => {'data': rows};

Map<String, dynamic> _row(String name, List<Map<String, dynamic>> values) => {
  'name': name,
  'values': values,
};

void main() {
  group('FacebookPageInsightsService', () {
    test(
      'fetches each metric separately and keeps the token out of the URL',
      () async {
        final adapter = _GraphAdapter(
          200,
          _ok([
            _row('page_media_view', [
              {'value': 100, 'end_time': '2026-11-06T08:00:00+0000'},
              {'value': 120, 'end_time': '2026-11-07T08:00:00+0000'},
            ]),
            _row('page_post_engagements', [
              {'value': 10, 'end_time': '2026-11-06T08:00:00+0000'},
              {'value': 12, 'end_time': '2026-11-07T08:00:00+0000'},
            ]),
            _row('page_follows', [
              {'value': 300, 'end_time': '2026-11-07T08:00:00+0000'},
            ]),
          ]),
        );

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
        expect(insights.unavailableMetrics, isEmpty);

        // One request per metric so a rejected metric cannot hide the others.
        expect(adapter.requests, hasLength(3));
        final metrics = [
          for (final request in adapter.requests)
            request.uri.queryParameters['metric'],
        ];
        expect(metrics, contains('page_media_view'));
        expect(metrics, contains('page_follows'));
        expect(metrics, contains('page_post_engagements'));

        final request = adapter.lastRequest!;
        expect(request.uri.toString(), contains('/v23.0/page-1/insights'));
        expect(request.headers['Authorization'], contains(_token));
        expect(request.uri.queryParameters.values, isNot(contains(_token)));
        expect(request.uri.queryParameters['date_preset'], 'last_7d');
        expect(request.uri.queryParameters['period'], 'day');
      },
    );

    test('uses last_28d for the default range', () async {
      final adapter = _GraphAdapter(200, _ok([]));

      await _service(adapter).fetch(pageId: 'page-1', token: _token);

      expect(
        adapter.lastRequest!.uri.queryParameters['date_preset'],
        'last_28d',
      );
    });

    test('uses last_90d for the 90 day range', () async {
      final adapter = _GraphAdapter(200, _ok([]));

      await _service(adapter).fetch(pageId: 'page-1', token: _token, days: 90);

      expect(
        adapter.lastRequest!.uri.queryParameters['date_preset'],
        'last_90d',
      );
    });

    test('fetchPrevious asks for an explicit since/until window', () async {
      final adapter = _GraphAdapter(200, _ok([]));

      await _service(adapter)
          .fetchPrevious(pageId: 'page-1', token: _token, days: 28);

      expect(adapter.requests, hasLength(3));
      for (final request in adapter.requests) {
        final params = request.uri.queryParameters;
        expect(params['period'], 'day');
        expect(params.containsKey('date_preset'), isFalse);
        final since = int.parse(params['since']!);
        final until = int.parse(params['until']!);
        expect(until - since, const Duration(days: 28).inSeconds);
        expect(until, lessThan(DateTime.now().millisecondsSinceEpoch ~/ 1000));
      }
    });

    test(
      'fetchPrevious keeps partial data when a metric is rejected',
      () async {
        final insights = await _service(
          _GraphAdapter(
            500,
            null,
            byMetric: {
              'page_media_view': _GraphReply(
                200,
                _ok([
                  _row('page_media_view', [
                    {'value': 9, 'end_time': '2026-10-20T08:00:00+0000'},
                  ]),
                ]),
              ),
              'page_post_engagements': _GraphReply(400, {
                'error': {'code': 100, 'message': 'nope'},
              }),
              'page_follows': _GraphReply(200, _ok([])),
            },
          ),
        ).fetchPrevious(pageId: 'page-1', token: _token, days: 7);

        expect(insights.rangeDays, 7);
        expect(insights.totalMediaViews, 9);
        expect(insights.unavailableMetrics, contains('page_post_engagements'));
      },
    );

    test('a missing metric stays null and never drags others down', () async {
      final insights = await _service(
        _GraphAdapter(
          200,
          _ok([
            _row('page_media_view', [
              {'value': 5, 'end_time': '2026-11-07T08:00:00+0000'},
            ]),
          ]),
        ),
      ).fetch(pageId: 'page-1', token: _token);

      expect(insights.totalMediaViews, 5);
      expect(insights.totalFollows, isNull);
      expect(insights.totalEngagements, isNull);
      expect(insights.hasFollows, isFalse);
    });

    test(
      'one rejected metric returns partial data instead of failing',
      () async {
        final insights = await _service(
          _GraphAdapter(
            500,
            null,
            byMetric: {
              'page_media_view': _GraphReply(
                200,
                _ok([
                  _row('page_media_view', [
                    {'value': 42, 'end_time': '2026-11-07T08:00:00+0000'},
                  ]),
                ]),
              ),
              'page_post_engagements': _GraphReply(
                200,
                _ok([
                  _row('page_post_engagements', [
                    {'value': 7, 'end_time': '2026-11-07T08:00:00+0000'},
                  ]),
                ]),
              ),
              'page_follows': _GraphReply(400, {
                'error': {
                  'code': 100,
                  'message': 'The value must be a valid insights metric.',
                },
              }),
            },
          ),
        ).fetch(pageId: 'page-1', token: _token);

        expect(insights.totalMediaViews, 42);
        expect(insights.totalEngagements, 7);
        expect(insights.totalFollows, isNull);
        expect(insights.unavailableMetrics, contains('page_follows'));
      },
    );

    test('empty data returns an empty snapshot', () async {
      final insights = await _service(_GraphAdapter(200, _ok([])))
          .fetch(pageId: 'page-1', token: _token);

      expect(insights.points, isEmpty);
      expect(insights.hasAny, isFalse);
    });

    test('a 400 keeps Meta\'s real explanation instead of guessing', () async {
      const detail = 'Please reduce the amount of data you are asking for.';
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 100, 'message': detail},
        }),
      );

      try {
        await service.fetch(pageId: 'page-1', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.insightsUnavailable);
        expect(e.message, contains(detail));
        expect(e.message, isNot(contains('metric names may have changed')));
        expect(e.graphMessage, detail);
      }
    });

    test('the 100-like minimum is called out explicitly', () async {
      const detail =
          'Page Insights data is only available on Pages with 100 or more '
          'likes.';
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 100, 'message': detail},
        }),
      );

      try {
        await service.fetch(pageId: 'page-1', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.message, contains('100 Page likes'));
        expect(e.message, contains(detail));
      }
    });

    test(
      '190 with a Page Access Token message is not an expired token',
      () async {
        const detail = 'This method must be called with a Page Access Token.';
        final service = _service(
          _GraphAdapter(400, {
            'error': {'code': 190, 'message': detail},
          }),
        );

        try {
          await service.fetch(pageId: 'page-1', token: _token);
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.pageTokenRequired);
          expect(e.needsReconnect, isTrue);
          expect(e.message, contains('Connect Pages'));
        }
      },
    );

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
      final adapter = _GraphAdapter(200, _ok([]));
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
      expect(adapter.requests, isEmpty);
    });
  });
}
