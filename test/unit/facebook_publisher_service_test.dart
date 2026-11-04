import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/core/network/interceptors/auth_interceptor.dart';
import 'package:oreamnos/core/network/interceptors/error_interceptor.dart';
import 'package:oreamnos/core/network/interceptors/retry_interceptor.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

/// Canned Graph responses through the REAL [ApiClient] pipeline
/// (Auth → Retry → ErrorMapping), mirroring
/// `test/unit/curator_error_paths_test.dart:_StatusAdapter`.
class _GraphAdapter implements HttpClientAdapter {
  _GraphAdapter(this.status, this.body);

  /// Null body simulates a transport failure (no response ever arrives).
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
    await for (final _ in requestStream ?? const Stream.empty()) {}
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

ApiClient _fastApiClient(_GraphAdapter adapter) {
  final apiClient = ApiClient();
  apiClient.dio.httpClientAdapter = adapter;
  // Fast retry for tests (production uses 4x500ms→60s).
  apiClient.dio.interceptors.clear();
  apiClient.dio.interceptors.addAll([
    AuthInterceptor(),
    RetryInterceptor(
      dio: apiClient.dio,
      maxRetries: 1,
      baseDelayMs: 10,
      maxDelayMs: 20,
    ),
    ErrorMappingInterceptor(),
  ]);
  return apiClient;
}

FacebookPublisherService _service(_GraphAdapter adapter) =>
    FacebookPublisherService(_fastApiClient(adapter));

const _token = 'EAAtestToken123';
const _goldGraphBody = {
  'error': {'code': 190, 'message': 'Error validating access token'},
};

Future<String> _tempPng() async {
  final dir = await Directory.systemTemp.createTemp('oreamnos_fb');
  final file = File('${dir.path}/card.png');
  await file.writeAsBytes(List<int>.generate(64, (i) => i));
  return file.path;
}

void main() {
  group('FacebookPublisherService', () {
    group('verify', () {
      test('GET /me returns the Page; token only in Bearer header', () async {
        final adapter = _GraphAdapter(200, {
          'id': '123456',
          'name': 'Oreamnos FC',
        });
        final page = await _service(adapter).verify(_token);

        expect(page.id, '123456');
        expect(page.name, 'Oreamnos FC');
        final request = adapter.lastRequest!;
        expect(request.uri.toString(), contains('/v23.0/me'));
        expect(request.headers['Authorization'], contains(_token));
        // Token contract: never in the URL.
        expect(request.uri.queryParameters.values, isNot(contains(_token)));
      });

      test('empty token throws unknown kind', () async {
        final service = _service(_GraphAdapter(200, {}));
        expect(
          () => service.verify('   '),
          throwsA(
            isA<FacebookApiException>().having(
              (e) => e.kind,
              'kind',
              FacebookApiErrorKind.unknown,
            ),
          ),
        );
      });

      test('code 190 maps to expiredToken with reconnect hint', () async {
        final service = _service(_GraphAdapter(400, _goldGraphBody));
        try {
          await service.verify(_token);
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.expiredToken);
          expect(e.code, 190);
          expect(e.needsReconnect, isTrue);
        }
      });

      test('code 200/10 maps to permission', () async {
        final service = _service(
          _GraphAdapter(400, {
            'error': {'code': 200, 'message': 'Permissions error'},
          }),
        );
        try {
          await service.verify(_token);
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.permission);
          expect(e.code, 200);
        }
      });

      test('codes 4/17/32/613 map to rateLimit', () async {
        for (final code in const [4, 17, 32, 613]) {
          final service = _service(
            _GraphAdapter(400, {
              'error': {
                'code': code,
                'message': 'Application request limit reached',
              },
            }),
          );
          try {
            await service.verify(_token);
            fail('should throw');
          } on FacebookApiException catch (e) {
            expect(
              e.kind,
              FacebookApiErrorKind.rateLimit,
              reason: 'code $code',
            );
          }
        }
      });

      test('code 506 (or subcode) maps to duplicate', () async {
        final service = _service(
          _GraphAdapter(400, {
            'error': {'code': 506, 'message': 'Duplicate Post'},
          }),
        );
        try {
          await service.publishText(
            pageId: '123456',
            token: _token,
            message: 'Same text',
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.duplicate);
          expect(e.code, 506);
        }
      });

      test('subcode 506 also maps to duplicate', () async {
        final service = _service(
          _GraphAdapter(400, {
            'error': {'code': 100, 'error_subcode': 506, 'message': 'dup'},
          }),
        );
        try {
          await service.publishText(
            pageId: '123456',
            token: _token,
            message: 'Same text',
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.duplicate);
        }
      });

      test(
        'HTML 200 response is not classified as a network failure',
        () async {
          final apiClient = ApiClient();
          apiClient.dio.httpClientAdapter = _RawAdapter(
            200,
            '<!doctype html><html><body>Blocked by proxy</body></html>',
          );
          apiClient.dio.interceptors.clear();
          final service = FacebookPublisherService(apiClient);
          try {
            await service.verify(_token);
            fail('should throw');
          } on FacebookApiException catch (e) {
            expect(e.kind, isNot(FacebookApiErrorKind.network));
            expect(e.message, contains('web page'));
          }
        },
      );

      test('transport failure with no response maps to network', () async {
        final service = _service(_GraphAdapter(200, null));
        try {
          await service.verify(_token);
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.network);
          expect(e.networkIssue, FacebookNetworkIssue.connection);
          expect(e.message, contains("Can't reach Facebook"));
        }
      });
    });

    group('publishText', () {
      test('posts to /{page}/feed with token in body, never the URL', () async {
        final adapter = _GraphAdapter(200, {'id': '999_888'});
        final result = await _service(adapter).publishText(
          pageId: '123456',
          token: _token,
          message: 'FT: JDT 4 - 1 Terengganu #FAM',
        );

        final request = adapter.lastRequest!;
        expect(request.uri.toString(), contains('/v23.0/123456/feed'));
        expect(request.uri.queryParameters, isNot(contains('access_token')));
        expect(request.uri.toString(), isNot(contains('EAA')));
        expect(adapter.lastBody, contains('access_token='));
        expect(adapter.lastBody, contains('message='));

        expect(result.id, '999_888');
        expect(result.postId, '999_888');
        expect(result.permalink, 'https://www.facebook.com/999_888');
        expect(result.isPhoto, isFalse);
      });

      test('empty message throws before any request', () async {
        final adapter = _GraphAdapter(200, {'id': 'x'});
        final service = _service(adapter);
        expect(
          () => service.publishText(
            pageId: '123456',
            token: _token,
            message: '   ',
          ),
          throwsA(isA<FacebookApiException>()),
        );
        expect(adapter.lastRequest, isNull);
      });

      test('object id missing in response maps to unknown', () async {
        final service = _service(_GraphAdapter(200, {'unexpected': 1}));
        try {
          await service.publishText(
            pageId: '123456',
            token: _token,
            message: 'text',
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.unknown);
        }
      });
    });

    group('scheduling', () {
      test('publishText sends published=false + UTC timestamp', () async {
        final adapter = _GraphAdapter(200, {'id': 'sched_1'});
        final at = DateTime.now().add(const Duration(hours: 2));
        final result = await _service(adapter).publishText(
          pageId: '123456',
          token: _token,
          message: 'Later #FAM',
          scheduledAt: at,
        );
        expect(result.isScheduled, isTrue);
        expect(result.permalink, isEmpty);
        final body = adapter.lastBody!;
        expect(body, contains('published=false'));
        expect(body, contains('${at.toUtc().millisecondsSinceEpoch ~/ 1000}'));
        expect(adapter.lastRequest!.uri.toString(), isNot(contains('EAA')));
      });

      test('publishPhoto sends alt text and schedule fields', () async {
        final path = await _tempPng();
        final adapter = _GraphAdapter(200, {'id': 'p', 'post_id': 'q'});
        final at = DateTime.now().add(const Duration(hours: 3));
        await _service(adapter).publishPhoto(
          pageId: '123456',
          token: _token,
          filePath: path,
          message: 'caption',
          altText: 'A green football pitch',
          scheduledAt: at,
        );
        final fields = (adapter.lastRequest!.data as FormData).fields;
        expect(
          fields.firstWhere((e) => e.key == 'alt_text_custom').value,
          'A green football pitch',
        );
        expect(fields.firstWhere((e) => e.key == 'published').value, 'false');
        expect(
          fields.firstWhere((e) => e.key == 'scheduled_publish_time').value,
          '${at.toUtc().millisecondsSinceEpoch ~/ 1000}',
        );
      });

      test('cancelScheduled sends DELETE with token in the body', () async {
        final adapter = _GraphAdapter(200, {'success': true});
        await _service(adapter)
            .cancelScheduled(postId: '123_456', token: _token);
        expect(adapter.lastRequest!.method, 'DELETE');
        expect(adapter.lastRequest!.uri.toString(), contains('/123_456'));
        expect(adapter.lastBody, contains('access_token='));
        expect(adapter.lastRequest!.uri.toString(), isNot(contains('EAA')));
      });

      test('listScheduled parses data rows and UTC seconds', () async {
        final adapter = _GraphAdapter(200, {
          'data': [
            {
              'id': '1_2',
              'message': 'Soon',
              'scheduled_publish_time': 1893456000,
            },
          ],
        });
        final posts = await _service(adapter)
            .listScheduled(pageId: '123456', token: _token);
        expect(posts.single.id, '1_2');
        expect(posts.single.message, 'Soon');
        expect(
          posts.single.scheduledAt,
          DateTime.fromMillisecondsSinceEpoch(
            1893456000000,
            isUtc: true,
          ).toLocal(),
        );
      });
    });

    group('publishPhoto', () {
      test('multipart /photos uses post_id for the permalink', () async {
        final path = await _tempPng();
        final adapter = _GraphAdapter(200, {
          'id': 'photo_777',
          'post_id': '123456_999_777',
        });
        final result = await _service(adapter).publishPhoto(
          pageId: '123456',
          token: _token,
          filePath: path,
          message: 'FT: JDT wins #FAM',
        );

        final request = adapter.lastRequest!;
        expect(request.uri.toString(), contains('/v23.0/123456/photos'));
        expect(request.uri.queryParameters, isNot(contains('access_token')));
        expect(request.data, isA<FormData>());
        expect(
          (request.data as FormData).fields.map((e) => e.key),
          contains('access_token'),
        );
        expect(
          (request.data as FormData).files.map((e) => e.key),
          contains('source'),
        );

        expect(result.id, 'photo_777');
        expect(result.postId, '123456_999_777');
        expect(result.permalink, 'https://www.facebook.com/123456_999_777');
        expect(result.isPhoto, isTrue);
      });

      test(
        'photo upload overrides receiveTimeout to photoUploadTimeout',
        () async {
          final path = await _tempPng();
          final adapter = _GraphAdapter(200, {'id': 'p', 'post_id': 'q'});
          await _service(adapter)
              .publishPhoto(pageId: '123456', token: _token, filePath: path);
          // After the interceptor chain, the per-request override survives.
          expect(
            adapter.lastRequest!.receiveTimeout,
            AppConstants.photoUploadTimeout,
          );
        },
      );

      test('falls back to photo id when post_id is absent', () async {
        final path = await _tempPng();
        final adapter = _GraphAdapter(200, {'id': 'photo_only'});
        final result = await _service(adapter)
            .publishPhoto(pageId: '123456', token: _token, filePath: path);
        expect(result.permalink, 'https://www.facebook.com/photo_only');
      });

      test('photo upload failure maps Graph errors unchanged', () async {
        final path = await _tempPng();
        final service = _service(_GraphAdapter(400, _goldGraphBody));
        try {
          await service.publishPhoto(
            pageId: '123456',
            token: _token,
            filePath: path,
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.expiredToken);
          expect(e.needsReconnect, isTrue);
        }
      });
    });
    group('multi-photo publish', () {
      test(
        'uploadUnpublishedPhoto sends published=false and one source',
        () async {
          final path = await _tempPng();
          final adapter = _GraphAdapter(200, {'id': 'photo_1'});
          final id = await _service(adapter).uploadUnpublishedPhoto(
            pageId: '123456',
            token: _token,
            filePath: path,
            altText: 'Stadium at night',
          );

          expect(id, 'photo_1');
          final request = adapter.lastRequest!;
          expect(request.uri.toString(), contains('/v23.0/123456/photos'));
          expect(request.uri.toString(), isNot(contains('EAA')));
          final form = request.data as FormData;
          expect(
            form.fields.firstWhere((e) => e.key == 'published').value,
            'false',
          );
          expect(
            form.fields.firstWhere((e) => e.key == 'alt_text_custom').value,
            'Stadium at night',
          );
          expect(
            form.fields.firstWhere((e) => e.key == 'access_token').value,
            _token,
          );
          expect(form.files.map((e) => e.key), ['source']);
          expect(request.receiveTimeout, AppConstants.photoUploadTimeout);
        },
      );

      test('upload without a photo id maps to mediaUploadFailed', () async {
        final path = await _tempPng();
        final service = _service(_GraphAdapter(200, {'unexpected': 1}));
        try {
          await service.uploadUnpublishedPhoto(
            pageId: '123456',
            token: _token,
            filePath: path,
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.mediaUploadFailed);
        }
      });

      test(
        'publishMultiPhoto sends attached_media JSON, token in body',
        () async {
          final adapter = _GraphAdapter(200, {'id': 'post_1'});
          final result = await _service(adapter).publishMultiPhoto(
            pageId: '123456',
            token: _token,
            photoIds: const ['p1', 'p2', 'p3'],
            message: 'Four photos of the match',
          );

          final request = adapter.lastRequest!;
          expect(request.uri.toString(), contains('/v23.0/123456/feed'));
          expect(request.uri.toString(), isNot(contains('EAA')));
          final body = request.data as Map<String, dynamic>;
          expect(body['access_token'], _token);
          expect(body['message'], 'Four photos of the match');
          final media = body['attached_media'] as List;
          expect(media, hasLength(3));
          expect(media.first, {'media_fbid': 'p1'});
          expect(media.last, {'media_fbid': 'p3'});

          expect(result.id, 'post_1');
          expect(result.postId, 'post_1');
          expect(result.isPhoto, isTrue);
          expect(result.permalink, 'https://www.facebook.com/post_1');
        },
      );

      test('publishMultiPhoto adds schedule fields when scheduled', () async {
        final adapter = _GraphAdapter(200, {'id': 'sched_multi'});
        final at = DateTime.now().add(const Duration(hours: 5));
        final result = await _service(adapter).publishMultiPhoto(
          pageId: '123456',
          token: _token,
          photoIds: const ['p1', 'p2'],
          message: 'Later',
          scheduledAt: at,
        );
        final body = adapter.lastRequest!.data as Map<String, dynamic>;
        expect(body['published'], 'false');
        expect(
          body['scheduled_publish_time'],
          '${at.toUtc().millisecondsSinceEpoch ~/ 1000}',
        );
        expect(result.isScheduled, isTrue);
        expect(result.permalink, isEmpty);
      });

      test('empty photo list throws before any request', () async {
        final adapter = _GraphAdapter(200, {'id': 'x'});
        final service = _service(adapter);
        expect(
          () => service.publishMultiPhoto(
            pageId: '123456',
            token: _token,
            photoIds: const [],
            message: 'text',
          ),
          throwsA(isA<FacebookApiException>()),
        );
        expect(adapter.lastRequest, isNull);
      });

      test('deletePhoto uses DELETE with the token in the body', () async {
        final adapter = _GraphAdapter(200, {'success': true});
        await _service(adapter).deletePhoto(photoId: 'p1', token: _token);
        final request = adapter.lastRequest!;
        expect(request.method, 'DELETE');
        expect(request.uri.toString(), contains('/p1'));
        expect(request.uri.toString(), isNot(contains('EAA')));
        expect(adapter.lastBody, contains('access_token='));
      });
    });

    group('post lifecycle', () {
      test('deletePost uses DELETE with the token in the body', () async {
        final adapter = _GraphAdapter(200, {'success': true});
        await _service(adapter).deletePost(postId: '123_9', token: _token);
        final request = adapter.lastRequest!;
        expect(request.method, 'DELETE');
        expect(request.uri.toString(), contains('/v23.0/123_9'));
        expect(request.uri.toString(), isNot(contains('EAA')));
        expect(adapter.lastBody, contains('access_token='));
      });

      test('deletePost maps expired tokens', () async {
        final service = _service(_GraphAdapter(400, _goldGraphBody));
        try {
          await service.deletePost(postId: '123_9', token: _token);
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.expiredToken);
        }
      });

      test('updatePostMessage sends message + token in the body', () async {
        final adapter = _GraphAdapter(200, {'success': true});
        await _service(adapter).updatePostMessage(
          postId: '123_9',
          token: _token,
          message: 'Updated caption',
        );
        final request = adapter.lastRequest!;
        expect(request.method, 'POST');
        expect(request.uri.toString(), contains('/v23.0/123_9'));
        expect(request.uri.toString(), isNot(contains('EAA')));
        expect(adapter.lastBody, contains('message=Updated+caption'));
        expect(adapter.lastBody, contains('access_token='));
      });

      test('unsupported caption edit gets a fixable message', () async {
        final service = _service(
          _GraphAdapter(400, {
            'error': {'code': 100, 'message': 'Unsupported post request'},
          }),
        );
        try {
          await service.updatePostMessage(
            postId: '123_9',
            token: _token,
            message: 'New caption',
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.unknown);
          expect(e.message, contains('Delete and repost'));
        }
      });

      test('empty edit message is rejected before any request', () async {
        final adapter = _GraphAdapter(200, {'success': true});
        final service = _service(adapter);
        expect(
          () => service.updatePostMessage(
            postId: '123_9',
            token: _token,
            message: '   ',
          ),
          throwsA(isA<FacebookApiException>()),
        );
        expect(adapter.lastRequest, isNull);
      });
    });
    group('story publishing', () {
      test(
        'publishPhotoStory posts photo_id with the token in the body',
        () async {
          final adapter = _GraphAdapter(200, {
            'success': true,
            'post_id': 'story_1',
          });
          final result = await _service(adapter).publishPhotoStory(
            pageId: '123456',
            token: _token,
            photoId: 'photo_1',
          );
          final request = adapter.lastRequest!;
          expect(
            request.uri.toString(),
            contains('/v23.0/123456/photo_stories'),
          );
          expect(request.uri.toString(), isNot(contains('EAA')));
          expect(adapter.lastBody, contains('photo_id=photo_1'));
          expect(adapter.lastBody, contains('access_token='));
          expect(result.postId, 'story_1');
        },
      );

      test('missing Story id maps to storyUnavailable', () async {
        final service = _service(_GraphAdapter(200, {'success': true}));
        try {
          await service.publishPhotoStory(
            pageId: '123456',
            token: _token,
            photoId: 'photo_1',
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.storyUnavailable);
        }
      });

      test('unsupported Story maps to storyUnavailable', () async {
        final service = _service(
          _GraphAdapter(400, {
            'error': {'code': 100, 'message': 'Unsupported story request'},
          }),
        );
        try {
          await service.publishPhotoStory(
            pageId: '123456',
            token: _token,
            photoId: 'photo_1',
          );
          fail('should throw');
        } on FacebookApiException catch (e) {
          expect(e.kind, FacebookApiErrorKind.storyUnavailable);
        }
      });
    });
  });
}
