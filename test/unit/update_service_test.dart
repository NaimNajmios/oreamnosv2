import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/models/app_release.dart';
import 'package:oreamnos/data/services/update_service.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body);

  final int status;
  final String body;
  RequestOptions? lastOptions;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    lastOptions = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.error);

  final DioException error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw error;
  }

  @override
  void close({bool force = false}) {}
}

UpdateService _service(HttpClientAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return UpdateService.withClient(dio);
}

Map<String, dynamic> _releaseJson({
  String tag = 'v1.2.0',
  List<Map<String, dynamic>>? assets,
}) => {
  'tag_name': tag,
  'name': 'Oreamnos $tag',
  'body': '## What changed\n- Something',
  'html_url': 'https://github.com/NaimNajmios/oreamnosv2/releases/tag/$tag',
  'published_at': '2026-11-01T10:00:00Z',
  'prerelease': false,
  'assets': assets ?? [],
};

void main() {
  test('requests the latest release with GitHub headers', () async {
    final adapter = _StubAdapter(200, jsonEncode(_releaseJson()));
    await _service(adapter).fetchLatestRelease();

    final options = adapter.lastOptions!;
    expect(adapter.requestCount, 1);
    expect(
      options.uri.toString(),
      contains('/repos/NaimNajmios/oreamnosv2/releases/latest'),
    );
    expect(options.headers['User-Agent'], 'oreamnosv2');
    expect(options.headers['Accept'], 'application/vnd.github+json');
    expect(options.headers['X-GitHub-Api-Version'], '2022-11-28');
  });

  test('parses a release and picks the APK asset', () async {
    final adapter = _StubAdapter(
      200,
      jsonEncode(
        _releaseJson(
          assets: [
            {
              'name': 'notes.txt',
              'browser_download_url': 'https://x/notes.txt',
              'size': 1,
            },
            {
              'name': 'oreamnosv2-v1.2.0.apk',
              'browser_download_url': 'https://x/app.apk',
              'size': 12345,
            },
            {
              'name': 'second.apk',
              'browser_download_url': 'https://x/second.apk',
              'size': 9,
            },
          ],
        ),
      ),
    );

    final release = await _service(adapter).fetchLatestRelease();

    expect(release, isNotNull);
    expect(release!.tag, 'v1.2.0');
    expect(release.version, '1.2.0');
    expect(release.apkUrl, 'https://x/app.apk');
    expect(release.apkSizeBytes, 12345);
    expect(release.isPrerelease, isFalse);
    expect(release.body, contains('What changed'));
    expect(release.publishedAt.isUtc, isTrue);
  });

  test('a release without an APK asset still parses', () async {
    final adapter = _StubAdapter(200, jsonEncode(_releaseJson()));
    final release = await _service(adapter).fetchLatestRelease();

    expect(release, isNotNull);
    expect(release!.apkUrl, isNull);
    expect(release.hasApk, isFalse);
  });

  test('404 means no published release yet', () async {
    final adapter = _StubAdapter(404, jsonEncode({'message': 'Not Found'}));
    expect(await _service(adapter).fetchLatestRelease(), isNull);
  });

  test('403 and 429 surface as rate limiting', () async {
    for (final status in [403, 429]) {
      final adapter = _StubAdapter(
        status,
        jsonEncode({'message': 'rate limit'}),
      );
      expect(
        () => _service(adapter).fetchLatestRelease(),
        throwsA(isA<UpdateRateLimitedException>()),
      );
    }
  });

  test('a server error is a plain check failure', () async {
    final adapter = _StubAdapter(500, jsonEncode({'message': 'oops'}));
    expect(
      () => _service(adapter).fetchLatestRelease(),
      throwsA(
        isA<UpdateCheckException>().having(
          (e) => e.isNetwork,
          'isNetwork',
          isFalse,
        ),
      ),
    );
  });

  test('malformed JSON and non-object payloads are handled', () async {
    for (final body in ['not json', '', '[]', 'null']) {
      final adapter = _StubAdapter(200, body);
      expect(
        () => _service(adapter).fetchLatestRelease(),
        throwsA(isA<UpdateCheckException>()),
        reason: 'body: $body',
      );
    }
  });

  test('connection errors are marked as network failures', () async {
    final adapter = _ThrowingAdapter(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/'),
        reason: 'offline',
      ),
    );

    expect(
      () => _service(adapter).fetchLatestRelease(),
      throwsA(
        isA<UpdateCheckException>().having(
          (e) => e.isNetwork,
          'isNetwork',
          isTrue,
        ),
      ),
    );
  });

  test('timeouts are marked as network failures', () async {
    final adapter = _ThrowingAdapter(
      DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: RequestOptions(path: '/'),
      ),
    );

    expect(
      () => _service(adapter).fetchLatestRelease(),
      throwsA(
        isA<UpdateCheckException>().having(
          (e) => e.isNetwork,
          'isNetwork',
          isTrue,
        ),
      ),
    );
  });

  test('release JSON tolerates missing fields', () {
    final release = AppRelease.fromJson({'tag_name': 'v2.0.0'});
    expect(release.version, '2.0.0');
    expect(release.body, isEmpty);
    expect(release.htmlUrl, isEmpty);
    expect(release.apkUrl, isNull);
  });

  test('a hyphenated tag is treated as a pre-release', () {
    final release = AppRelease.fromJson({'tag_name': 'v2.0.0-beta.1'});
    expect(release.isPrerelease, isTrue);
  });
}
