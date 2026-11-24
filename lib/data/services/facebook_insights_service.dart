import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_post_insights.dart';
import 'facebook_diagnostics.dart';
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

  /// The post insights fetched so far, one request per metric. A metric
  /// Graph rejects is recorded in [FacebookPostInsightsResult.failures];
  /// only a total failure throws, so one rejected metric no longer hides
  /// the others. Metrics that are missing or malformed stay `null` —
  /// never zero — so the UI can hide them.
  Future<FacebookPostInsightsResult> fetch({
    required String postId,
    required String token,
  }) async {
    if (postId.trim().isEmpty || token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Insights are unavailable for this post.',
      );
    }
    final fetchedAt = DateTime.now();
    final failures = <FacebookApiException>[];
    var insights = FacebookPostInsights(fetchedAt: fetchedAt);
    for (final metric in [
      FacebookMetricNames.postTotalMediaViewUnique,
      FacebookMetricNames.postReactionsByTypeTotal,
      FacebookMetricNames.postActivityByActionType,
    ]) {
      try {
        insights = _merge(
          insights,
          await _fetchMetric(
            postId: postId,
            token: token,
            metric: metric,
            fetchedAt: fetchedAt,
          ),
        );
      } on FacebookApiException catch (e) {
        failures.add(e);
        FacebookDiagnostics.failure('Insights refresh', e, statusCode: e.code);
      }
    }
    if (failures.length == _metricNames.length) throw failures.first;
    FacebookDiagnostics.event('Post insights refreshed');
    return FacebookPostInsightsResult(
      insights: insights,
      failures: List.unmodifiable(failures),
    );
  }

  static const List<String> _metricNames = [
    FacebookMetricNames.postTotalMediaViewUnique,
    FacebookMetricNames.postReactionsByTypeTotal,
    FacebookMetricNames.postActivityByActionType,
  ];

  /// One Graph request for [metric]; only that metric is in the response.
  Future<FacebookPostInsights> _fetchMetric({
    required String postId,
    required String token,
    required String metric,
    required DateTime fetchedAt,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(postId)}',
        queryParameters: {'fields': 'insights.metric($metric)'},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: AppConstants.facebookWriteTimeout,
        ),
      );
      final data = facebookRequireObject(
        response.data,
        action: 'post insights',
      );
      return _parse(data, fetchedAt);
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
        final converted = FacebookApiException(
          kind: FacebookApiErrorKind.insightsUnavailable,
          message: FacebookDiagnostics.metaReason(mapped.graphMessage),
          code: mapped.code,
          subcode: mapped.subcode,
          traceId: mapped.traceId,
        );
        FacebookDiagnostics.failure(
          'Insights refresh',
          converted,
          statusCode: e.response?.statusCode,
        );
        throw converted;
      }
      FacebookDiagnostics.failure(
        'Insights refresh',
        mapped,
        statusCode: e.response?.statusCode,
      );
      throw mapped;
    } catch (_) {
      const error = FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Insights are unavailable for this post.',
      );
      FacebookDiagnostics.failure('Insights refresh', error);
      throw error;
    }
  }

  /// Merges a successfully fetched metric into the accumulated result.
  static FacebookPostInsights _merge(
    FacebookPostInsights base,
    FacebookPostInsights next,
  ) {
    final reactionsByType = next.reactionsByType ?? base.reactionsByType;
    return FacebookPostInsights(
      uniqueViewers: next.uniqueViewers ?? base.uniqueViewers,
      reactionsByType: reactionsByType,
      reactions: reactionsByType?.values.fold<int>(
        0,
        (sum, count) => sum + count,
      ),
      activityByActionType:
          next.activityByActionType ?? base.activityByActionType,
      fetchedAt: base.fetchedAt,
    );
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
      final insights = _parseEngagement(data, DateTime.now());
      FacebookDiagnostics.event('Engagement refreshed');
      return insights;
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      final mapped = FacebookApiException.fromGraph(
        e.response?.statusCode,
        _asMap(e.response?.data),
        isNetworkFailure: e.response == null,
        networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
      );
      FacebookDiagnostics.failure(
        'Engagement refresh',
        mapped,
        statusCode: e.response?.statusCode,
      );
      throw mapped;
    } catch (_) {
      const error = FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Engagement is unavailable for this post.',
      );
      FacebookDiagnostics.failure('Engagement refresh', error);
      throw error;
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
