import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_page_service.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
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

FacebookPageService _service(_GraphAdapter adapter) {
  final apiClient = ApiClient();
  apiClient.dio.httpClientAdapter = adapter;
  apiClient.dio.interceptors.clear();
  return FacebookPageService(apiClient, FacebookPublisherService(apiClient));
}

const _userToken = 'EAABuserToken';

void main() {
  group('FacebookPageService', () {
    test('parses every Page with its derived token', () async {
      final adapter = _GraphAdapter(200, {
        'data': [
          {
            'id': '1',
            'name': 'Trace Football',
            'access_token': 'page-token-1',
            'picture': {
              'data': {'url': 'https://example.com/1.png'},
            },
          },
          {'id': '2', 'name': 'Second Page', 'access_token': 'page-token-2'},
        ],
      });
      final pages = await _service(adapter).listPagesFromUserToken(_userToken);

      expect(pages, hasLength(2));
      expect(pages.first.page.id, '1');
      expect(pages.first.page.name, 'Trace Football');
      expect(pages.first.page.pictureUrl, 'https://example.com/1.png');
      expect(pages.first.pageToken, 'page-token-1');

      final request = adapter.lastRequest!;
      expect(request.uri.toString(), contains('/v23.0/me/accounts'));
      expect(request.headers['Authorization'], contains(_userToken));
      // Token contract: never in the URL.
      expect(request.uri.queryParameters.values, isNot(contains(_userToken)));
    });

    test('skips rows without an id or token', () async {
      final adapter = _GraphAdapter(200, {
        'data': [
          {'id': '1', 'access_token': 't1'},
          {'id': '2'},
          {'access_token': 't3'},
          {'id': '4', 'access_token': 't4'},
        ],
      });
      final pages = await _service(adapter).listPagesFromUserToken(_userToken);
      expect(pages.map((p) => p.page.id), ['1', '4']);
    });

    test('empty data maps to pageTokenExchangeFailed', () async {
      final service = _service(_GraphAdapter(200, {'data': []}));
      try {
        await service.listPagesFromUserToken(_userToken);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.pageTokenExchangeFailed);
        expect(e.message, isNot(contains(_userToken)));
      }
    });

    test('missing pages_show_list maps to a friendly exchange error', () async {
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 200, 'message': 'Permissions error'},
        }),
      );
      try {
        await service.listPagesFromUserToken(_userToken);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.pageTokenExchangeFailed);
        expect(e.message, contains('pages_show_list'));
        expect(e.message, isNot(contains(_userToken)));
      }
    });

    test('code 190 stays expiredToken', () async {
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 190, 'message': 'Error validating access token'},
        }),
      );
      try {
        await service.listPagesFromUserToken(_userToken);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.expiredToken);
        expect(e.needsReconnect, isTrue);
      }
    });

    test('blank token throws before any request', () async {
      final adapter = _GraphAdapter(200, {'data': []});
      final service = _service(adapter);
      expect(
        () => service.listPagesFromUserToken('   '),
        throwsA(isA<FacebookApiException>()),
      );
      expect(adapter.lastRequest, isNull);
    });
  });
}
