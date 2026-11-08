import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_post_insights.dart';
import 'facebook_metric_names.dart';
import 'facebook_network_error.dart';
import 'facebook_response_guard.dart';

/// Fetches post insights with a single Graph call.
///
/// Token handling: `Authorization: Bearer` on the GET, never a query
/// parameter, so the token cannot leak through the debug interceptor.
@lazySingleton
class FacebookInsightsService {
  FacebookInsightsService([ApiClient? client])
    : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  String get _pathBase =>
      '${AppConstants.facebookGraphBaseUrl}/'
      '${AppConstants.facebookGraphVersion}';

  /// Returns whatever metrics Graph exposes. Metrics that are missing or
  /// malformed stay `null` — never zero — so the UI can hide them.
  Future<FacebookPostInsights> fetch({
    required String postId,
    required String token,
  }) async {
    if (postId.trim().isEmpty || token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Insights are unavailable for this post.',
      );
    }
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(postId)}',
        queryParameters: const {
          'fields':
              'insights.metric('
              '${FacebookMetricNames.postTotalMediaViewUnique},'
              '${FacebookMetricNames.postReactionsByTypeTotal},'
              '${FacebookMetricNames.postActivityByActionType})',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: AppConstants.facebookWriteTimeout,
        ),
      );
      final data = facebookRequireObject(
        response.data,
        action: 'post insights',
      );
      return _parse(data, DateTime.now());
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      final body = _asMap(e.response?.data);
      final mapped = FacebookApiException.fromGraph(
        e.response?.statusCode,
        body,
        isNetworkFailure: e.response == null,
        networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
      );
      if (mapped.kind == FacebookApiErrorKind.unknown &&
          e.response?.statusCode == 400) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.insightsUnavailable,
          message:
              'Meta reports these post insights are unavailable. The metric '
              'names may have changed.',
          code: mapped.code,
          subcode: mapped.subcode,
        );
      }
      throw mapped;
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Insights are unavailable for this post.',
      );
    }
  }

  /// Stable engagement summary fields. Kept separate from [fetch] so a
  /// retired insight metric cannot take the reaction/comment/share badges
  /// down with it.
  Future<FacebookPostInsights> fetchEngagement({
    required String postId,
    required String token,
  }) async {
    if (postId.trim().isEmpty || token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Engagement is unavailable for this post.',
      );
    }
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(postId)}',
        queryParameters: const {
          'fields': 'reactions.summary(true),comments.summary(true),shares',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: AppConstants.facebookWriteTimeout,
        ),
      );
      final data = facebookRequireObject(
        response.data,
        action: 'post engagement',
      );
      return _parseEngagement(data, DateTime.now());
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      throw FacebookApiException.fromGraph(
        e.response?.statusCode,
        _asMap(e.response?.data),
        isNetworkFailure: e.response == null,
        networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
      );
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Engagement is unavailable for this post.',
      );
    }
  }

  static FacebookPostInsights _parse(
    Map<String, dynamic> body,
    DateTime fetchedAt,
  ) {
    final insights = body['insights'];
    final raw = insights is Map ? insights['data'] : null;
    final metrics = <String, Object?>{};
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map) continue;
        final name = entry['name']?.toString() ?? '';
        if (name.isNotEmpty) metrics[name] = entry['values'];
      }
    }

    int? single(String name) {
      final values = metrics[name];
      if (values is! List || values.isEmpty) return null;
      final first = values.first;
      final value = first is Map ? first['value'] : first;
      return _asInt(value);
    }

    Map<String, int>? reactionMap() {
      final values = metrics[FacebookMetricNames.postReactionsByTypeTotal];
      return _intMap(values);
    }

    final reactionsByType = reactionMap();
    final reactions = reactionsByType?.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    return FacebookPostInsights(
      uniqueViewers: single(FacebookMetricNames.postTotalMediaViewUnique),
      reactions: reactions,
      reactionsByType: reactionsByType,
      activityByActionType: _intMap(
        metrics[FacebookMetricNames.postActivityByActionType],
      ),
      fetchedAt: fetchedAt,
    );
  }

  /// Reads Graph's `summary.total_count` shape, accepting `count` too.
  static FacebookPostInsights _parseEngagement(
    Map<String, dynamic> body,
    DateTime fetchedAt,
  ) {
    int? summary(Object? section) {
      if (section is! Map) return null;
      final nested = section['summary'];
      if (nested is Map) {
        final count = _asInt(nested['total_count']);
        if (count != null) return count;
      }
      return _asInt(section['count']);
    }

    return FacebookPostInsights(
      reactions: summary(body['reactions']),
      comments: summary(body['comments']),
      shares: summary(body['shares']),
      fetchedAt: fetchedAt,
    );
  }

  static Map<String, int>? _intMap(Object? values) {
    if (values is! List || values.isEmpty) return null;
    final first = values.first;
    final value = first is Map ? first['value'] : first;
    if (value is! Map) return null;
    final result = <String, int>{};
    for (final entry in value.entries) {
      final count = _asInt(entry.value);
      if (count != null) result[entry.key.toString()] = count;
    }
    return result.isEmpty ? null : result;
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt();
    return null;
  }

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
