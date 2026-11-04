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
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    requestCount++;
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

class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter(this.body);

  final Map<String, dynamic> body;
  int failures = 1;
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (failures > 0) {
      failures--;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'transient',
      );
    }
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      200,
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

    test('a 200 Page list is terminal and makes one request', () async {
      final adapter = _GraphAdapter(200, {
        'data': [
          {'id': '1', 'name': 'Page', 'access_token': 'token'},
        ],
      });
      final service = _service(adapter);
      final pages = await service.listPagesFromUserToken(_userToken);
      expect(pages.single.page.id, '1');
      expect(adapter.requestCount, 1);
    });

    test('HTML 200 response is not classified as a network failure', () async {
      final apiClient = ApiClient();
      apiClient.dio.httpClientAdapter = _RawAdapter(
        200,
        '<!doctype html><html><body>Blocked by proxy</body></html>',
      );
      apiClient.dio.interceptors.clear();
      final service = FacebookPageService(
        apiClient,
        FacebookPublisherService(apiClient),
      );
      try {
        await service.listPagesFromUserToken(_userToken);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.pageTokenExchangeFailed);
        expect(e.message, contains('web page'));
        expect(e.kind, isNot(FacebookApiErrorKind.network));
      }
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

    test('a transport failure is not duplicated by the service', () async {
      final adapter = _FlakyAdapter({
        'data': [
          {'id': '1', 'name': 'Page', 'access_token': 'token'},
        ],
      });
      final apiClient = ApiClient();
      apiClient.dio.httpClientAdapter = adapter;
      apiClient.dio.interceptors.clear();
      final service = FacebookPageService(
        apiClient,
        FacebookPublisherService(apiClient),
      );

      await expectLater(
        () => service.listPagesFromUserToken(_userToken),
        throwsA(
          isA<FacebookApiException>().having(
            (e) => e.kind,
            'kind',
            FacebookApiErrorKind.network,
          ),
        ),
      );
      expect(adapter.calls, 1);
    });

    test('does not retry an expired token', () async {
      final adapter = _GraphAdapter(400, {
        'error': {'code': 190, 'message': 'Error validating access token'},
      });
      final service = _service(adapter);
      try {
        await service.listPagesFromUserToken(_userToken);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.expiredToken);
      }
      // One request only; auth failures are not transient.
      expect(adapter.requestCount, 1);
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
