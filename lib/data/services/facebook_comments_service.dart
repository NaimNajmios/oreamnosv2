import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_comment.dart';
import 'facebook_diagnostics.dart';
import 'facebook_network_error.dart';
import 'facebook_response_guard.dart';

/// Page comment moderation through Graph v23.0.
///
/// Token contract: `Authorization: Bearer` on GETs, `access_token` in the form
/// body on writes. The token never rides the URL.
@lazySingleton
class FacebookCommentsService {
  FacebookCommentsService([ApiClient? client])
    : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  String get _pathBase =>
      '${AppConstants.facebookGraphBaseUrl}/'
      '${AppConstants.facebookGraphVersion}';

  Future<FacebookCommentPage> list({
    required String postId,
    required String token,
    String? after,
    int limit = 25,
  }) async {
    if (postId.trim().isEmpty || token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.permission,
        message: 'Connect your Page before opening comments.',
      );
    }
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(postId)}/comments',
        queryParameters: {
          'fields':
              'id,message,from{id,name},created_time,like_count,'
              'comment_count,is_hidden,can_hide,can_remove,permalink_url',
          'limit': '$limit',
          'order': 'reverse_chronological',
          if (after != null && after.isNotEmpty) 'after': after,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: AppConstants.facebookWriteTimeout,
        ),
      );
      return _parsePage(
        facebookRequireObject(response.data, action: 'comments'),
      );
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      throw _friendly(_map(e, 'Comments load'));
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'Could not load comments. Try again.',
      );
    }
  }

  Future<void> reply({
    required String commentId,
    required String token,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.unknown,
        message: 'Write a reply first.',
      );
    }
    try {
      await _client.post<dynamic>(
        '$_pathBase/${Uri.encodeComponent(commentId)}/comments',
        data: {'access_token': token, 'message': message},
        options: _formOptions(),
      );
      FacebookDiagnostics.event('Comment replied');
    } on DioException catch (e) {
      throw _friendly(_map(e, 'Comment reply'));
    }
  }

  Future<void> setHidden({
    required String commentId,
    required String token,
    required bool hidden,
  }) async {
    try {
      await _client.post<dynamic>(
        '$_pathBase/${Uri.encodeComponent(commentId)}',
        data: {'access_token': token, 'is_hidden': hidden ? 'true' : 'false'},
        options: _formOptions(),
      );
      FacebookDiagnostics.event(hidden ? 'Comment hidden' : 'Comment shown');
    } on DioException catch (e) {
      throw _friendly(_map(e, hidden ? 'Comment hide' : 'Comment show'));
    }
  }

  Future<void> delete({
    required String commentId,
    required String token,
  }) async {
    try {
      await _client.delete<dynamic>(
        '$_pathBase/${Uri.encodeComponent(commentId)}',
        data: {'access_token': token},
        options: _formOptions(),
      );
      FacebookDiagnostics.event('Comment deleted');
    } on DioException catch (e) {
      throw _friendly(_map(e, 'Comment delete'));
    }
  }

  static FacebookCommentPage _parsePage(Map<String, dynamic> body) {
    final rows = body['data'];
    final comments = <FacebookComment>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;
        final map = row.cast<String, dynamic>();
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final from = map['from'];
        final author = from is Map ? from : const {};
        comments.add(
          FacebookComment(
            id: id,
            message: map['message']?.toString() ?? '',
            authorId: author['id']?.toString() ?? '',
            authorName: (author['name']?.toString() ?? '').trim().isEmpty
                ? 'Facebook user'
                : author['name'].toString(),
            createdAt: DateTime.tryParse(map['created_time']?.toString() ?? '')
                ?.toLocal(),
            likeCount: _asInt(map['like_count']) ?? 0,
            replyCount: _asInt(map['comment_count']) ?? 0,
            isHidden: map['is_hidden'] == true,
            canHide: map['can_hide'] == true,
            canRemove: map['can_remove'] == true,
            permalinkUrl: map['permalink_url']?.toString() ?? '',
          ),
        );
      }
    }
    String? nextCursor;
    final paging = body['paging'];
    if (paging is Map) {
      final cursors = paging['cursors'];
      if (cursors is Map) {
        final after = cursors['after']?.toString() ?? '';
        if (after.isNotEmpty) nextCursor = after;
      }
    }
    return FacebookCommentPage(comments: comments, nextCursor: nextCursor);
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt();
    return null;
  }

  FacebookApiException _map(DioException e, String action) {
    final mapped = FacebookApiException.fromGraph(
      e.response?.statusCode,
      _asMap(e.response?.data),
      isNetworkFailure: e.response == null,
      networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
    );
    FacebookDiagnostics.failure(
      action,
      mapped,
      statusCode: e.response?.statusCode,
    );
    return mapped;
  }

  static FacebookApiException _friendly(FacebookApiException e) {
    if (e.kind == FacebookApiErrorKind.permission) {
      return FacebookApiException(
        kind: FacebookApiErrorKind.permission,
        message:
            'This token is missing pages_manage_engagement. Reconnect with '
            'that permission to moderate comments.',
        code: e.code,
        subcode: e.subcode,
      );
    }
    return e;
  }

  static Options _formOptions() => Options(
    contentType: 'application/x-www-form-urlencoded',
    sendTimeout: AppConstants.facebookWriteTimeout,
    receiveTimeout: AppConstants.facebookWriteTimeout,
    extra: const {'graphWrite': true},
  );

  static Map<String, dynamic>? _asMap(Object? data) {
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
