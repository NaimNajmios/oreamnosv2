import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_comments_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

class _GraphAdapter implements HttpClientAdapter {
  _GraphAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic>? body;
  RequestOptions? lastRequest;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final bytes = <int>[];
    await for (final chunk in requestStream ?? const Stream.empty()) {
      bytes.addAll(chunk);
    }
    if (bytes.isNotEmpty) {
      lastBody = utf8.decode(bytes, allowMalformed: true);
    }
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

FacebookCommentsService _service(_GraphAdapter adapter) {
  final client = ApiClient();
  client.dio.httpClientAdapter = adapter;
  client.dio.interceptors.clear();
  return FacebookCommentsService(client);
}

const _token = 'EAAtestToken';

void main() {
  group('FacebookCommentsService', () {
    test(
      'list parses comments, missing authors, and the next cursor',
      () async {
        final adapter = _GraphAdapter(200, {
          'data': [
            {
              'id': 'c1',
              'message': 'Great post',
              'from': {'id': 'u1', 'name': 'Amin'},
              'created_time': '2026-11-04T10:00:00+0000',
              'like_count': 3,
              'comment_count': 2,
              'is_hidden': false,
              'can_hide': true,
              'can_remove': true,
            },
            {'id': 'c2', 'message': 'No author'},
          ],
          'paging': {
            'cursors': {'after': 'cursor-2'},
          },
        });
        final page = await _service(adapter)
            .list(postId: '123_9', token: _token);

        expect(page.comments, hasLength(2));
        expect(page.comments.first.authorName, 'Amin');
        expect(page.comments.first.likeCount, 3);
        expect(page.comments.first.replyCount, 2);
        expect(page.comments.first.canHide, isTrue);
        expect(page.comments.last.authorName, 'Facebook user');
        expect(page.nextCursor, 'cursor-2');

        final request = adapter.lastRequest!;
        expect(request.uri.toString(), contains('/v23.0/123_9/comments'));
        expect(request.headers['Authorization'], contains(_token));
        expect(request.uri.queryParameters.values, isNot(contains(_token)));
        expect(request.uri.queryParameters['limit'], '25');
      },
    );

    test(
      'list sends the after cursor and omits it on the first page',
      () async {
        final adapter = _GraphAdapter(200, {'data': []});
        final service = _service(adapter);
        await service.list(postId: 'p', token: _token);
        expect(adapter.lastRequest!.uri.queryParameters['after'], isNull);
        await service.list(postId: 'p', token: _token, after: 'abc');
        expect(adapter.lastRequest!.uri.queryParameters['after'], 'abc');
      },
    );

    test('empty data returns an empty page', () async {
      final page = await _service(_GraphAdapter(200, {'data': []}))
          .list(postId: 'p', token: _token);
      expect(page.comments, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('reply posts the message with the token in the body', () async {
      final adapter = _GraphAdapter(200, {'id': 'reply1'});
      await _service(adapter)
          .reply(commentId: 'c1', token: _token, message: 'Thanks!');
      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.uri.toString(), contains('/v23.0/c1/comments'));
      expect(request.uri.toString(), isNot(contains('EAA')));
      expect(adapter.lastBody, contains('message=Thanks'));
      expect(adapter.lastBody, contains('access_token='));
    });

    test('setHidden posts is_hidden true/false', () async {
      final adapter = _GraphAdapter(200, {'success': true});
      final service = _service(adapter);
      await service.setHidden(commentId: 'c1', token: _token, hidden: true);
      expect(adapter.lastBody, contains('is_hidden=true'));
      await service.setHidden(commentId: 'c1', token: _token, hidden: false);
      expect(adapter.lastBody, contains('is_hidden=false'));
      expect(adapter.lastRequest!.uri.toString(), isNot(contains('EAA')));
    });

    test('delete uses DELETE with the token in the body', () async {
      final adapter = _GraphAdapter(200, {'success': true});
      await _service(adapter).delete(commentId: 'c1', token: _token);
      expect(adapter.lastRequest!.method, 'DELETE');
      expect(adapter.lastRequest!.uri.toString(), contains('/c1'));
      expect(adapter.lastBody, contains('access_token='));
    });

    test('permission errors mention pages_manage_engagement', () async {
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 200, 'message': 'Permissions error'},
        }),
      );
      try {
        await service.list(postId: 'p', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.permission);
        expect(e.message, contains('pages_manage_engagement'));
      }
    });

    test('expired token maps to expiredToken', () async {
      final service = _service(
        _GraphAdapter(400, {
          'error': {'code': 190, 'message': 'Error validating access token'},
        }),
      );
      try {
        await service.list(postId: 'p', token: _token);
        fail('should throw');
      } on FacebookApiException catch (e) {
        expect(e.kind, FacebookApiErrorKind.expiredToken);
        expect(e.needsReconnect, isTrue);
      }
    });
  });
}
