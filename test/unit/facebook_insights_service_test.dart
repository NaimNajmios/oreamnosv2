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

FacebookInsightsService _service(_GraphAdapter adapter) {
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
      'parses all three metrics and keeps the token out of the URL',
      () async {
        final adapter = _GraphAdapter(
          200,
          _insights([
            {
              'name': 'post_impressions_unique',
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
              'name': 'post_clicks',
              'values': [
                {'value': '31'},
              ],
            },
          ]),
        );
        final insights = await _service(adapter)
            .fetch(postId: '123_456', token: _token);

        expect(insights.impressions, 1200);
        expect(insights.reactions, 84);
        expect(insights.clicks, 31);
        expect(insights.hasAny, isTrue);

        final request = adapter.lastRequest!;
        expect(request.uri.toString(), contains('/v23.0/123_456'));
        expect(request.headers['Authorization'], contains(_token));
        expect(request.uri.queryParameters.values, isNot(contains(_token)));
        expect(
          request.uri.queryParameters['fields'],
          contains('post_impressions_unique'),
        );
      },
    );

    test('parses the richer v13 metric set', () async {
      final insights = await _service(
        _GraphAdapter(
          200,
          _insights([
            {
              'name': 'post_impressions_unique',
              'values': [
                {'value': 120},
              ],
            },
            {
              'name': 'post_impressions',
              'values': [
                {'value': 300},
              ],
            },
            {
              'name': 'post_engaged_users',
              'values': [
                {'value': 45},
              ],
            },
            {
              'name': 'post_negative_feedback',
              'values': [
                {'value': 2},
              ],
            },
            {
              'name': 'post_reactions_by_type_total',
              'values': [
                {
                  'value': {'like': 10, 'love': 2},
                },
              ],
            },
          ]),
        ),
      ).fetch(postId: 'p', token: _token);
      expect(insights.impressions, 120);
      expect(insights.totalImpressions, 300);
      expect(insights.engagedUsers, 45);
      expect(insights.negativeFeedback, 2);
      expect(insights.reactions, 12);
      expect(insights.reactionsByType, {'like': 10, 'love': 2});
      expect(insights.clicks, isNull);
    });

    test('missing metrics stay null, never zero', () async {
      final adapter = _GraphAdapter(
        200,
        _insights([
          {
            'name': 'post_impressions_unique',
            'values': [
              {'value': 5},
            ],
          },
        ]),
      );
      final insights = await _service(adapter)
          .fetch(postId: 'p', token: _token);
      expect(insights.impressions, 5);
      expect(insights.reactions, isNull);
      expect(insights.clicks, isNull);
      expect(insights.hasAny, isTrue);
    });

    test('no insights block yields nulls and hasAny false', () async {
      final insights = await _service(_GraphAdapter(200, {'id': 'p'}))
          .fetch(postId: 'p', token: _token);
      expect(insights.hasAny, isFalse);
      expect(insights.impressions, isNull);
      expect(insights.reactions, isNull);
      expect(insights.clicks, isNull);
    });

    test('malformed metric values cannot crash the parser', () async {
      final insights = await _service(
        _GraphAdapter(
          200,
          _insights([
            {
              'name': 'post_impressions_unique',
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
            {'name': 'post_clicks', 'values': 'nope'},
          ]),
        ),
      ).fetch(postId: 'p', token: _token);
      expect(insights.impressions, isNull);
      expect(insights.reactions, isNull);
      expect(insights.clicks, isNull);
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
  });
}
