import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import 'facebook_diagnostics.dart';
import 'facebook_network_error.dart';
import 'facebook_response_guard.dart';

/// The Page resolved from `GET /me`. With a Page access token this returns
/// the Page itself, so the user only ever pastes one token (the manual
/// Page-id fallback in PreferencesService covers tokens where `/me`
/// misbehaves).
class FacebookPage {
  const FacebookPage({
    required this.id,
    required this.name,
    this.pictureUrl = '',
  });

  final String id;
  final String name;

  /// Public Page avatar (`picture.data.url`). Empty when Graph omits it.
  final String pictureUrl;

  @override
  bool operator ==(Object other) =>
      other is FacebookPage &&
      other.id == id &&
      other.name == name &&
      other.pictureUrl == pictureUrl;

  @override
  int get hashCode => Object.hash(id, name, pictureUrl);
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
    this.isScheduled = false,
    this.scheduledAt,
  });

  final String id;

  /// Feed post id — same as [id] for text posts, differs on photo posts.
  final String postId;

  /// Empty for scheduled posts (Graph only resolves it once live).
  final String permalink;
  final bool isPhoto;
  final bool isScheduled;
  final DateTime? scheduledAt;

  static String permalinkFor(String postId) =>
      'https://www.facebook.com/$postId';
}

/// One row from `GET /{page-id}/scheduled_posts`.
class FacebookScheduledPost {
  const FacebookScheduledPost({
    required this.id,
    required this.message,
    this.scheduledAt,
  });

  final String id;
  final String message;
  final DateTime? scheduledAt;
}

/// Result of a Page Story publish.
class FacebookStoryResult {
  const FacebookStoryResult({required this.postId});

  final String postId;
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
      final response = await _client.get<dynamic>(
        '$_pathBase/me',
        queryParameters: const {'fields': 'id,name,picture{url}'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = _asMap(response.data);
      if (data == null) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.unexpectedResponse,
          message: facebookUnexpectedResponseMessage(response.data),
        );
      }
      final id = data['id']?.toString() ?? '';
      if (id.isEmpty) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.unknown,
          message: 'Facebook returned no Page id for this token.',
        );
      }
      return FacebookPage(
        id: id,
        name: (data['name'] ?? 'Page').toString(),
        pictureUrl: _pictureUrl(data),
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
    DateTime? scheduledAt,
  }) async {
    if (message.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'The post text is empty.',
      );
    }
    try {
      final response = await _client.post<dynamic>(
        '$_pathBase/$pageId/feed',
        data: {
          'message': message,
          'access_token': token,
          ...?_scheduleFields(scheduledAt),
        },
        options: _formOptions(
          receiveOverride: AppConstants.facebookWriteTimeout,
        ),
      );
      return _resultFrom(
        _requireObject(response.data, action: 'publish'),
        isPhoto: false,
        scheduledAt: scheduledAt,
      );
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
    String? altText,
    DateTime? scheduledAt,
    ProgressCallback? onSendProgress,
  }) async {
    final caption = message?.trim() ?? '';
    final alt = altText?.trim() ?? '';
    _validateUploadFile(filePath);
    final form = FormData.fromMap(<String, String>{
      if (caption.isNotEmpty) 'message': caption,
      if (alt.isNotEmpty) 'alt_text_custom': alt,
      ...?_scheduleFields(scheduledAt),
      'access_token': token,
    });
    form.files.add(MapEntry('source', await _imagePart(filePath)));
    try {
      final response = await _client.post<dynamic>(
        '$_pathBase/$pageId/photos',
        data: form,
        options: _formOptions(
          sendOverride: AppConstants.facebookUploadTimeout,
          receiveOverride: AppConstants.facebookUploadTimeout,
        ),
        onSendProgress: onSendProgress,
      );
      return _resultFrom(
        _requireObject(response.data, action: 'publish photo'),
        isPhoto: true,
        scheduledAt: scheduledAt,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Uploads a photo without publishing it (`published=false`) so it can be
  /// attached to a single feed post later. Multi-photo posts use this for
  /// every image, then `publishMultiPhoto`.
  Future<String> uploadUnpublishedPhoto({
    required String pageId,
    required String token,
    required String filePath,
    String? altText,
    ProgressCallback? onSendProgress,
  }) async {
    final alt = altText?.trim() ?? '';
    _validateUploadFile(filePath);
    final form = FormData.fromMap(<String, String>{
      'published': 'false',
      if (alt.isNotEmpty) 'alt_text_custom': alt,
      'access_token': token,
    });
    form.files.add(MapEntry('source', await _imagePart(filePath)));
    try {
      final response = await _client.post<dynamic>(
        '$_pathBase/$pageId/photos',
        data: form,
        options: _formOptions(
          sendOverride: AppConstants.facebookUploadTimeout,
          receiveOverride: AppConstants.facebookUploadTimeout,
        ),
        onSendProgress: onSendProgress,
      );
      final id =
          _requireObject(
            response.data,
            action: 'upload photo',
          )['id']?.toString() ??
          '';
      if (id.isEmpty) {
        throw const FacebookApiException(
          kind: FacebookApiErrorKind.mediaUploadFailed,
          message: 'Facebook did not return a photo id for this upload.',
        );
      }
      return id;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Creates one feed post from already-uploaded (unpublished) photos.
  /// `attached_media` is sent as JSON in the body, so the token never rides
  /// the URL.
  Future<FacebookPublishResult> publishMultiPhoto({
    required String pageId,
    required String token,
    required List<String> photoIds,
    required String message,
    DateTime? scheduledAt,
  }) async {
    if (photoIds.isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.mediaUploadFailed,
        message: 'Attach at least one photo before posting.',
      );
    }
    if (message.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'The post text is empty.',
      );
    }
    try {
      final response = await _client.post<dynamic>(
        '$_pathBase/$pageId/feed',
        data: {
          'message': message,
          'attached_media': [
            for (final id in photoIds) {'media_fbid': id},
          ],
          'access_token': token,
          ...?_scheduleFields(scheduledAt),
        },
        options: Options(
          contentType: 'application/json',
          receiveTimeout: AppConstants.facebookWriteTimeout,
          extra: const {'graphWrite': true},
        ),
      );
      return _resultFrom(
        _requireObject(response.data, action: 'publish multi-photo'),
        isPhoto: true,
        scheduledAt: scheduledAt,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Best-effort cleanup for unpublished photos after a failed multi-photo
  /// publish. Never throws (the original failure is the one shown to users).
  Future<void> deletePhoto({
    required String photoId,
    required String token,
  }) async {
    if (photoId.isEmpty) return;
    try {
      await _client.delete<dynamic>(
        '$_pathBase/$photoId',
        data: {'access_token': token},
        options: _formOptions(),
      );
      FacebookDiagnostics.event('Photo deleted');
    } catch (_) {}
  }

  /// Publishes an already-uploaded unpublished photo as a Page Story.
  /// The photo must not have been used in a published feed post.
  Future<FacebookStoryResult> publishPhotoStory({
    required String pageId,
    required String token,
    required String photoId,
  }) async {
    if (photoId.isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.storyUnavailable,
        message: 'The Story image was not uploaded.',
      );
    }
    try {
      final response = await _client.post<dynamic>(
        '$_pathBase/$pageId/photo_stories',
        data: {'access_token': token, 'photo_id': photoId},
        options: _formOptions(
          receiveOverride: AppConstants.facebookWriteTimeout,
        ),
      );
      final data = _requireObject(response.data, action: 'publish Story');
      final postId = data['post_id']?.toString() ?? '';
      if (postId.isEmpty) {
        throw const FacebookApiException(
          kind: FacebookApiErrorKind.storyUnavailable,
          message: 'Facebook returned no Story id.',
        );
      }
      FacebookDiagnostics.event('Story published', pageId: pageId);
      return FacebookStoryResult(postId: postId);
    } on DioException catch (e) {
      final mapped = _map(e);
      if (mapped.kind == FacebookApiErrorKind.unknown) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.storyUnavailable,
          message:
              "Facebook couldn't publish this Story. The Page post can still "
              'be published.',
          code: mapped.code,
          subcode: mapped.subcode,
        );
      }
      throw mapped;
    }
  }

  /// Deletes a live post (or a scheduled one) on Graph. The token rides the
  /// form body so it never appears in a URL.
  Future<void> deletePost({
    required String postId,
    required String token,
  }) async {
    if (postId.isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'Facebook returned no post id for this record.',
      );
    }
    try {
      await _client.delete<dynamic>(
        '$_pathBase/$postId',
        data: {'access_token': token},
        options: _formOptions(
          receiveOverride: AppConstants.facebookWriteTimeout,
        ),
      );
      FacebookDiagnostics.event('Post deleted');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Updates a published post's caption. Graph may reject this for some post
  /// types; the caller surfaces a fixable message instead of changing local
  /// state.
  Future<void> updatePostMessage({
    required String postId,
    required String token,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'The caption cannot be empty.',
      );
    }
    try {
      await _client.post<dynamic>(
        '$_pathBase/$postId',
        data: {'access_token': token, 'message': message},
        options: _formOptions(
          receiveOverride: AppConstants.facebookWriteTimeout,
        ),
      );
      FacebookDiagnostics.event('Post caption updated');
    } on DioException catch (e) {
      final mapped = _map(e);
      if (mapped.kind == FacebookApiErrorKind.unknown) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.unknown,
          message:
              "Facebook doesn't allow editing this post's caption. "
              'Delete and repost instead.',
          code: mapped.code,
          subcode: mapped.subcode,
        );
      }
      throw mapped;
    }
  }

  /// Cancels a scheduled post (`DELETE /{post-id}`). The token rides the
  /// form body so it never appears in a URL.
  Future<void> cancelScheduled({
    required String postId,
    required String token,
  }) async {
    try {
      await _client.delete<dynamic>(
        '$_pathBase/$postId',
        data: {'access_token': token},
        options: _formOptions(
          receiveOverride: AppConstants.facebookWriteTimeout,
        ),
      );
      FacebookDiagnostics.event('Scheduled post cancelled');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Moves a scheduled post (`POST /{post-id}` with a new timestamp).
  Future<void> reschedule({
    required String postId,
    required String token,
    required DateTime scheduledAt,
  }) async {
    try {
      await _client.post<dynamic>(
        '$_pathBase/$postId',
        data: {
          'access_token': token,
          'scheduled_publish_time':
              '${scheduledAt.toUtc().millisecondsSinceEpoch ~/ 1000}',
        },
        options: _formOptions(
          receiveOverride: AppConstants.facebookWriteTimeout,
        ),
      );
      FacebookDiagnostics.event('Scheduled post rescheduled');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Lists the Page's upcoming scheduled posts. Used by the history screen to
  /// reconcile local records after a cancel/publish happened elsewhere.
  Future<List<FacebookScheduledPost>> listScheduled({
    required String pageId,
    required String token,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/$pageId/scheduled_posts',
        queryParameters: const {
          'fields': 'id,message,scheduled_publish_time',
          'limit': '50',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = _asMap(response.data);
      final rows = data?['data'];
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map((row) {
            final map = row.cast<String, dynamic>();
            final seconds = int.tryParse(
              map['scheduled_publish_time']?.toString() ?? '',
            );
            return FacebookScheduledPost(
              id: map['id']?.toString() ?? '',
              message: map['message']?.toString() ?? '',
              scheduledAt: seconds == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      seconds * 1000,
                      isUtc: true,
                    ).toLocal(),
            );
          })
          .where((post) => post.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Form-encoded POSTs: Graph's canonical OAuth body shape. JSON content
  /// type from the pooled BaseOptions is overridden here so `access_token`
  /// rides the body without URL encoding pitfalls.
  static Options _formOptions({
    Duration? sendOverride,
    Duration? receiveOverride,
  }) => Options(
    contentType: 'application/x-www-form-urlencoded',
    sendTimeout: sendOverride,
    receiveTimeout: receiveOverride,
    extra: const {'graphWrite': true},
  );

  /// Graph answers should be JSON objects. A 200 HTML/plain/proxy body must
  /// become `unexpectedResponse`, not a fake network failure.
  static Map<String, dynamic> _requireObject(
    Object? data, {
    required String action,
  }) => facebookRequireObject(data, action: action);

  /// Prefer the real file extension/content type; Graph validates the image.
  static Future<MultipartFile> _imagePart(String filePath) async {
    final ext = _imageExtension(filePath);
    final mime = ext == '.png'
        ? DioMediaType('image', 'png')
        : DioMediaType('image', 'jpeg');
    return MultipartFile.fromFile(
      filePath,
      filename: 'oreamnos_card$ext',
      contentType: mime,
    );
  }

  static String _imageExtension(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '.jpg';
    // Cropper output is JPEG by default; never claim an unknown extension.
    return '.jpg';
  }

  static const int _maxUploadBytes = 10 * 1024 * 1024;

  /// Cheap local preflight so invalid files fail with a fixable message
  /// instead of a Graph 400.
  static void _validateUploadFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.mediaUploadFailed,
        message: 'The image file is missing. Re-attach it and try again.',
      );
    }
    final size = file.lengthSync();
    if (size <= 0) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.mediaUploadFailed,
        message: 'The image file is empty. Re-attach it and try again.',
      );
    }
    if (size > _maxUploadBytes) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.mediaUploadFailed,
        message: 'The image is too large for Facebook (max 10 MB).',
      );
    }
  }

  /// Prefers our Graph-specific mapping over the interceptor's decorated
  /// `extra['failure']`: Graph error bodies carry code/subcode, which the
  /// generic AI-provider texts can't express (and `ErrorMappingInterceptor`
  /// only decorates — the response body stays intact for us).
  FacebookApiException _map(DioException e) {
    final body = _asMap(e.response?.data);
    assert(() {
      final error = body?['error'];
      final map = error is Map ? error : const {};
      debugPrint(
        '[FB] graph error status=${e.response?.statusCode} '
        'code=${map['code']} subcode=${map['error_subcode']} '
        'message=${map['message']} '
        'userTitle=${map['error_user_title']} '
        'userMsg=${map['error_user_msg']}',
      );
      return true;
    }());
    final mapped = FacebookApiException.fromGraph(
      e.response?.statusCode,
      body,
      isNetworkFailure: e.response == null,
      networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
    );
    FacebookDiagnostics.failure(
      'Graph request',
      mapped,
      statusCode: e.response?.statusCode,
    );
    return mapped;
  }

  FacebookPublishResult _resultFrom(
    Map<String, dynamic>? body, {
    required bool isPhoto,
    DateTime? scheduledAt,
  }) {
    final id = body?['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'Facebook returned no post id for this publish.',
      );
    }
    var postId = id;
    if (isPhoto) {
      final rawPostId = body?['post_id']?.toString() ?? '';
      if (rawPostId.isNotEmpty) postId = rawPostId;
    }
    final scheduled = scheduledAt != null;
    return FacebookPublishResult(
      id: id,
      postId: postId,
      permalink: scheduled ? '' : FacebookPublishResult.permalinkFor(postId),
      isPhoto: isPhoto,
      isScheduled: scheduled,
      scheduledAt: scheduledAt,
    );
  }

  /// Form fields for a scheduled publish — `published=false` plus the Unix
  /// timestamp Graph expects. Returns null for an immediate post.
  static Map<String, String>? _scheduleFields(DateTime? scheduledAt) {
    if (scheduledAt == null) return null;
    return {
      'published': 'false',
      'scheduled_publish_time':
          '${scheduledAt.toUtc().millisecondsSinceEpoch ~/ 1000}',
    };
  }

  /// Pulls `picture.data.url` out of a `/me` response defensively.
  static String _pictureUrl(Map<String, dynamic>? data) {
    final picture = data?['picture'];
    if (picture is! Map) return '';
    final nested = picture['data'];
    if (nested is Map) return (nested['url'] ?? '').toString();
    return '';
  }

  /// Graph answers are always JSON objects, but a proxy/parse hiccup can
  /// leave `data` as a String (ResponseType.json fallback) — decode defensively.
  static Map<String, dynamic>? _asMap(Object? data) =>
      facebookObjectOrNull(data);
}
