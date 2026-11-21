import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../models/app_release.dart';

/// Thrown when the update check cannot complete for a reason the UI should
/// explain (offline, server error, malformed payload).
class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message, {this.isNetwork = false});

  final String message;

  /// True for connection problems, so the UI can say "offline" instead of
  /// blaming GitHub.
  final bool isNetwork;

  @override
  String toString() => message;
}

/// Thrown when GitHub's unauthenticated rate limit is exhausted.
class UpdateRateLimitedException extends UpdateCheckException {
  const UpdateRateLimitedException([
    super.message = 'GitHub is rate limiting update checks. Try again later.',
  ]);
}

/// Reads the latest published release of the app straight from GitHub.
///
/// Uses its own [Dio] rather than the shared [ApiClient]: GitHub needs no
/// provider credentials, and the shared client's interceptors would rewrite
/// 403/429 responses into app-specific failures before we can inspect them.
@lazySingleton
class UpdateService {
  UpdateService() : _dio = _buildDio();

  /// Test seam: lets a fake [HttpClientAdapter] stand in for the network.
  UpdateService.withClient(Dio dio) : _dio = dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
      ),
    );
  }

  static const String owner = 'NaimNajmios';
  static const String repo = 'oreamnosv2';
  static const Duration _timeout = Duration(seconds: 10);

  static final Uri latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/$owner/$repo/releases/latest',
  );

  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    // GitHub rejects requests without a User-Agent.
    'User-Agent': 'oreamnosv2',
  };

  final Dio _dio;

  /// Returns `null` when the repository has no published, non-prerelease
  /// release yet (GitHub answers 404).
  Future<AppRelease?> fetchLatestRelease() async {
    final Response<dynamic> response;
    try {
      response = await _dio
          .getUri<dynamic>(
            latestReleaseUri,
            options: Options(
              headers: _headers,
              // Inspect every status ourselves instead of raising for 4xx.
              validateStatus: (_) => true,
              // Decode ourselves so a malformed payload is reported as an
              // update-check failure instead of a generic transport error.
              responseType: ResponseType.plain,
            ),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const UpdateCheckException(
        'The update check timed out.',
        isNetwork: true,
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (_) {
      throw const UpdateCheckException('The update check failed.');
    }

    switch (response.statusCode) {
      case 200:
        return _parse(response.data);
      case 404:
        return null;
      case 403:
      case 429:
        throw const UpdateRateLimitedException();
      default:
        throw UpdateCheckException(
          'GitHub returned ${response.statusCode ?? 'no status'}.',
        );
    }
  }

  AppRelease _parse(dynamic data) {
    Object? decoded = data;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } on FormatException {
        throw const UpdateCheckException('GitHub sent an unexpected response.');
      }
    }
    if (decoded is Map<String, dynamic>) {
      try {
        return AppRelease.fromJson(decoded);
      } catch (_) {
        throw const UpdateCheckException('GitHub sent an unexpected response.');
      }
    }
    if (decoded is Map) {
      return AppRelease.fromJson(decoded.cast<String, dynamic>());
    }
    throw const UpdateCheckException('GitHub sent an unexpected response.');
  }

  /// Downloads [release]'s APK to [targetPath] and verifies its SHA-256
  /// against the release digest reported by GitHub.
  ///
  /// Reports byte progress through [onProgress] (`received` / `total`). Any
  /// failure throws [UpdateCheckException] so the caller owns the UI state
  /// machine around the download.
  Future<void> downloadUpdate(
    AppRelease release,
    String targetPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final url = release.apkUrl;
    if (url == null || url.isEmpty) {
      throw const UpdateCheckException(
        'No APK is available to download for this release.',
      );
    }

    try {
      await _dio.downloadUri(
        Uri.parse(url),
        targetPath,
        onReceiveProgress: (int received, int? total) {
          onProgress?.call(received, total ?? 0);
        },
        options: Options(receiveTimeout: const Duration(minutes: 5)),
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }

    final file = File(targetPath);
    if (!await file.exists()) {
      throw const UpdateCheckException(
        'The update download finished without producing a file.',
      );
    }
    final bytes = await file.readAsBytes();
    final actualHex = sha256.convert(bytes).toString();
    final expectedHex = release.apkSha256;
    if (expectedHex != null &&
        expectedHex.isNotEmpty &&
        expectedHex != actualHex) {
      throw const UpdateCheckException(
        'The downloaded update failed its checksum verification.',
      );
    }
  }

  UpdateCheckException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const UpdateCheckException(
          'The update check timed out.',
          isNetwork: true,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const UpdateCheckException(
          "Couldn't reach GitHub. Check your connection.",
          isNetwork: true,
        );
      default:
        return UpdateCheckException('The update check failed: ${error.type}.');
    }
  }
}
