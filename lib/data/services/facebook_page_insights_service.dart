import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_page_insights.dart';
import 'facebook_diagnostics.dart';
import 'facebook_metric_names.dart';
import 'facebook_network_error.dart';
import 'facebook_response_guard.dart';

/// Page-level performance for the Publish overview.
///
/// Requires `read_insights` + `pages_read_engagement` and the ANALYZE Page
/// task. Token handling matches the rest of the feature: Bearer on GETs.
@lazySingleton
class FacebookPageInsightsService {
  FacebookPageInsightsService([ApiClient? client])
    : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  String get _pathBase =>
      '${AppConstants.facebookGraphBaseUrl}/'
      '${AppConstants.facebookGraphVersion}';

  Future<FacebookPageInsights> fetch({
    required String pageId,
    required String token,
    int days = 28,
  }) async {
    if (pageId.trim().isEmpty || token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.permission,
        message: 'Connect your Page to load performance.',
      );
    }
    final preset = days <= 7
        ? 'last_7d'
        : days <= 28
        ? 'last_28d'
        : 'last_90d';
    const metrics = [
      FacebookMetricNames.pageMediaView,
      FacebookMetricNames.pageFollows,
      FacebookMetricNames.pagePostEngagements,
    ];

    // Meta rejects the whole request when any single metric is invalid. Fetch
    // them concurrently so one slow metric cannot block the other two.
    final results = await Future.wait(
      metrics.map(
        (metric) => _fetchMetric(metric, pageId, token, preset: preset),
      ),
    );

    final rows = <Map<String, dynamic>>[];
    final unavailable = <String>[];
    FacebookApiException? firstFailure;
    var succeeded = 0;
    for (final result in results) {
      if (result.failure == null) {
        rows.addAll(result.rows);
        succeeded++;
        continue;
      }
      unavailable.add(result.metric);
      firstFailure ??= result.failure;
    }

    if (succeeded == 0 && firstFailure != null) throw firstFailure;
    return _parse(
      {'data': rows},
      pageId,
      DateTime.now(),
      unavailableMetrics: unavailable,
      rangeDays: days,
    );
  }

  /// Fetches the window immediately before the current range. Failures are
  /// non-fatal: the caller keeps the current period and labels the comparison
  /// as unavailable.
  Future<FacebookPageInsights> fetchPrevious({
    required String pageId,
    required String token,
    int days = 28,
  }) async {
    if (pageId.trim().isEmpty || token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.permission,
        message: 'Connect your Page to load performance.',
      );
    }
    final now = DateTime.now().toUtc();
    final until = now.subtract(Duration(days: days));
    final since = until.subtract(Duration(days: days));
    const metrics = [
      FacebookMetricNames.pageMediaView,
      FacebookMetricNames.pageFollows,
      FacebookMetricNames.pagePostEngagements,
    ];
    final results = await Future.wait(
      metrics.map(
        (metric) => _fetchMetric(
          metric,
          pageId,
          token,
          since: since.millisecondsSinceEpoch ~/ 1000,
          until: until.millisecondsSinceEpoch ~/ 1000,
        ),
      ),
    );
    final rows = <Map<String, dynamic>>[];
    final unavailable = <String>[];
    for (final result in results) {
      if (result.failure == null) {
        rows.addAll(result.rows);
      } else {
        unavailable.add(result.metric);
      }
    }
    return _parse(
      {'data': rows},
      pageId,
      DateTime.now(),
      unavailableMetrics: unavailable,
      rangeDays: days,
    );
  }

  Future<_MetricResult> _fetchMetric(
    String metric,
    String pageId,
    String token, {
    String? preset,
    int? since,
    int? until,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(pageId)}/insights',
        queryParameters: {
          'metric': metric,
          'period': 'day',
          'date_preset': ?preset,
          if (since != null) 'since': '$since',
          if (until != null) 'until': '$until',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: AppConstants.facebookWriteTimeout,
        ),
      );
      final data = facebookRequireObject(
        response.data,
        action: 'page performance',
      );
      final metricRows = data['data'];
      return _MetricResult.success(
        metricRows is List
            ? metricRows
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList(growable: false)
            : const [],
      );
    } on FacebookApiException catch (e) {
      if (_isFatal(e)) rethrow;
      return _MetricResult.failure(metric, e);
    } on DioException catch (e) {
      final mapped = _mapGraphError(e);
      if (_isFatal(mapped)) throw mapped;
      return _MetricResult.failure(metric, mapped);
    } catch (_) {
      return _MetricResult.failure(
        metric,
        const FacebookApiException(
          kind: FacebookApiErrorKind.insightsUnavailable,
          message: 'Could not load Page performance.',
        ),
      );
    }
  }

  static bool _isFatal(FacebookApiException e) {
    return e.kind == FacebookApiErrorKind.network ||
        e.kind == FacebookApiErrorKind.expiredToken ||
        e.kind == FacebookApiErrorKind.pageTokenRequired ||
        e.kind == FacebookApiErrorKind.permission ||
        e.kind == FacebookApiErrorKind.rateLimit;
  }

  FacebookApiException _mapGraphError(DioException e) {
    final mapped = FacebookApiException.fromGraph(
      e.response?.statusCode,
      _asMap(e.response?.data),
      isNetworkFailure: e.response == null,
      networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
    );
    FacebookDiagnostics.failure(
      'Page insights',
      mapped,
      statusCode: e.response?.statusCode,
    );
    assert(() {
      debugPrint(
        '[FB] insights failed status=${e.response?.statusCode} '
        'code=${mapped.code} subcode=${mapped.subcode} '
        'message=${mapped.graphMessage}',
      );
      return true;
    }());
    if (mapped.kind == FacebookApiErrorKind.permission ||
        e.response?.statusCode == 403) {
      return FacebookApiException(
        kind: FacebookApiErrorKind.permission,
        message:
            'Page performance needs read_insights + pages_read_engagement '
            'and the ANALYZE Page task. Reconnect the Page token.',
        code: mapped.code,
        subcode: mapped.subcode,
        graphMessage: mapped.graphMessage,
      );
    }
    if (mapped.kind == FacebookApiErrorKind.unknown &&
        e.response?.statusCode == 400) {
      return FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: _insightsUnavailableMessage(mapped.graphMessage),
        code: mapped.code,
        subcode: mapped.subcode,
        graphMessage: mapped.graphMessage,
      );
    }
    return mapped;
  }

  /// Keeps Meta's real explanation visible instead of guessing that metric
  /// names changed. Adds the documented 100-like minimum when present.
  static String _insightsUnavailableMessage(String? detail) {
    final text = detail?.trim() ?? '';
    if (text.isEmpty) {
      return 'Meta rejected the Page insights request.';
    }
    final lower = text.toLowerCase();
    if (lower.contains('100 likes') || lower.contains('100 or more likes')) {
      return 'Page Insights requires at least 100 Page likes. Meta: $text';
    }
    return 'Meta rejected the Page insights request. $text';
  }

  static FacebookPageInsights _parse(
    Map<String, dynamic> body,
    String pageId,
    DateTime fetchedAt, {
    List<String> unavailableMetrics = const [],
    int rangeDays = 28,
  }) {
    final rows = body['data'];
    if (rows is! List) {
      return FacebookPageInsights(
        pageId: pageId,
        points: const [],
        fetchedAt: fetchedAt,
        unavailableMetrics: unavailableMetrics,
        rangeDays: rangeDays,
      );
    }
    final byDay = <String, PageInsightPoint>{};
    var hasMediaViews = false;
    var hasFollows = false;
    var hasEngagements = false;

    for (final row in rows) {
      if (row is! Map) continue;
      final name = row['name']?.toString() ?? '';
      final values = row['values'];
      if (values is! List) continue;
      for (final entry in values) {
        if (entry is! Map) continue;
        final value = _asInt(entry['value']);
        if (value == null) continue;
        final day = _day(entry['end_time']) ?? _day(entry['time']);
        if (day == null) continue;
        final key = '${day.year}-${day.month}-${day.day}';
        final point =
            byDay[key] ??
            PageInsightPoint(day: DateTime(day.year, day.month, day.day));
        if (name == FacebookMetricNames.pageMediaView) {
          hasMediaViews = true;
          byDay[key] = point.copyWith(mediaViews: value);
        } else if (name == FacebookMetricNames.pageFollows) {
          hasFollows = true;
          byDay[key] = point.copyWith(follows: value);
        } else if (name == FacebookMetricNames.pagePostEngagements) {
          hasEngagements = true;
          byDay[key] = point.copyWith(engagements: value);
        }
      }
    }

    final points = byDay.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return FacebookPageInsights(
      pageId: pageId,
      points: points,
      fetchedAt: fetchedAt,
      hasMediaViews: hasMediaViews,
      hasFollows: hasFollows,
      hasEngagements: hasEngagements,
      unavailableMetrics: unavailableMetrics,
      rangeDays: rangeDays,
    );
  }

  static DateTime? _day(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString();
    final parsed = DateTime.tryParse(text);
    return parsed?.toLocal();
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

/// Outcome of a single metric request.
class _MetricResult {
  const _MetricResult.success(this.rows) : metric = '', failure = null;

  const _MetricResult.failure(this.metric, this.failure) : rows = const [];

  final String metric;
  final List<Map<String, dynamic>> rows;
  final FacebookApiException? failure;
}
