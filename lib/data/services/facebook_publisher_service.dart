import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';

/// The Page resolved from `GET /me`. With a Page access token this returns
/// the Page itself, so the user only ever pastes one token (the manual
/// Page-id fallback in PreferencesService covers tokens where `/me`
/// misbehaves).
class FacebookPage {
  const FacebookPage({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is FacebookPage && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Result of a successful publish. On photo posts Graph returns both the
/// photo `id` and a `post_id`; the permalink is built from `post_id`
/// (`https://www.facebook.com/{post_id}`), which is the shareable feed link.
class FacebookPublishResult {
  const FacebookPublishResult({
    required this.id,
    required this.postId,
    required this.permalink,
    required this.isPhoto,
  });

  final String id;

  /// Feed post id — same as [id] for text posts, differs on photo posts.
  final String postId;
  final String permalink;
  final bool isPhoto;

  static String permalinkFor(String postId) =>
      'https://www.facebook.com/$postId';
}

/// Publishes text posts and photos to a Facebook Page via maintainable
/// Graph API calls on the pooled [ApiClient] (share timeouts, the
/// ErrorMapping/retry pipeline and the debug LoggingInterceptor).
///
/// Token handling contract: the token is sent as a POST body field, or as
/// `Authorization: Bearer` on GETs — never as a URL query parameter, so it
/// can never print from the debug interceptor (`LoggingInterceptor.redact`
/// covers `?key=` and `Bearer`, not `?access_token=`). Requests/response
/// bodies are never forwarded to `LogService`.
@lazySingleton
class FacebookPublisherService {
  FacebookPublisherService([ApiClient? client])
    : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  String get _pathBase =>
      '${AppConstants.facebookGraphBaseUrl}/'
      '${AppConstants.facebookGraphVersion}';

  /// Resolves the token's identity: `GET /me?fields=id,name`.
  Future<FacebookPage> verify(String token) async {
    if (token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'Paste a Page access token first.',
      );
    }
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '$_pathBase/me',
        queryParameters: const {'fields': 'id,name'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = _asMap(response.data);
      final id = data?['id']?.toString() ?? '';
      if (id.isEmpty) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.unknown,
          message: 'Facebook returned no Page id for this token.',
        );
      }
      return FacebookPage(
        id: id,
        name: (data?['name'] ?? 'Page').toString(),
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Publishes a text post to the Page feed (`POST /{page-id}/feed`).
  /// Returns the created post with its permalink.
  Future<FacebookPublishResult> publishText({
    required String pageId,
    required String token,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'The post text is empty.',
      );
    }
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '$_pathBase/$pageId/feed',
        data: {'message': message, 'access_token': token},
        options: _formOptions(),
      );
      return _resultFrom(_asMap(response.data), isPhoto: false);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Publishes a photo to the Page (`POST /{page-id}/photos`, multipart).
  /// The optional caption becomes the photo post's `message`. Uses
  /// `AppConstants.photoUploadTimeout`: see that constant for why the shared
  /// 15s receive window is lethal here (client abort → server posts anyway
  /// → retry trips the duplicate rejection).
  Future<FacebookPublishResult> publishPhoto({
    required String pageId,
    required String token,
    required String filePath,
    String? message,
  }) async {
    final caption = message?.trim() ?? '';
    final form = FormData.fromMap(<String, String>{
      if (caption.isNotEmpty) 'message': caption,
      'access_token': token,
    });
    form.files.add(
      await MultipartFile.fromFile(
        filePath,
        filename: 'oreamnos_card.png',
      ),
    );
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '$_pathBase/$pageId/photos',
        data: form,
        options: _formOptions(receiveOverride: AppConstants.photoUploadTimeout),
      );
      return _resultFrom(_asMap(response.data), isPhoto: true);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Form-encoded POSTs: Graph's canonical OAuth body shape. JSON content
  /// type from the pooled BaseOptions is overridden here so `access_token`
  /// rides the body without URL encoding pitfalls.
  static Options _formOptions({Duration? receiveOverride}) => Options(
    contentType: 'application/x-www-form-urlencoded',
    receiveTimeout: receiveOverride,
  );

  /// Prefers our Graph-specific mapping over the interceptor's decorated
  /// `extra['failure']`: Graph error bodies carry code/subcode, which the
  /// generic AI-provider texts can't express (and `ErrorMappingInterceptor`
  /// only decorates — the response body stays intact for us).
  FacebookApiException _map(DioException e) {
    return FacebookApiException.fromGraph(
      e.response?.statusCode,
      _asMap(e.response?.data),
      isNetworkFailure: e.response == null,
    );
  }

  FacebookPublishResult _resultFrom(
    Map<String, dynamic>? body, {
    required bool isPhoto,
  }) {
    final id = body?['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'Facebook returned no post id for this publish.',
      );
    }
    final postId = (isPhoto ? body?['post_id']?.toString() : id) ?? id;
    return FacebookPublishResult(
      id: id,
      postId: postId,
      permalink: FacebookPublishResult.permalinkFor(postId),
      isPhoto: isPhoto,
    );
  }

  /// Graph answers are always JSON objects, but a proxy/parse hiccup can
  /// leave `data` as a String (ResponseType.json fallback) — decode defensively.
  static Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return null;
  }
}
