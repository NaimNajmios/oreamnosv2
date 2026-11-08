import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_page_insights.dart';
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
    final until = DateTime.now();
    final since = until.subtract(Duration(days: days));
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(pageId)}/insights',
        queryParameters: {
          'metric': [
            FacebookMetricNames.pageMediaView,
            FacebookMetricNames.pageFollows,
            FacebookMetricNames.pagePostEngagements,
          ].join(','),
          'period': 'day',
          'since': '${since.toUtc().millisecondsSinceEpoch ~/ 1000}',
          'until': '${until.toUtc().millisecondsSinceEpoch ~/ 1000}',
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
      return _parse(data, pageId, DateTime.now());
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      final mapped = FacebookApiException.fromGraph(
        e.response?.statusCode,
        _asMap(e.response?.data),
        isNetworkFailure: e.response == null,
        networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
      );
      if (mapped.kind == FacebookApiErrorKind.permission ||
          e.response?.statusCode == 403) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.permission,
          message:
              'Page performance needs read_insights + pages_read_engagement '
              'and the ANALYZE Page task. Reconnect the Page token.',
          code: mapped.code,
          subcode: mapped.subcode,
        );
      }
      if (mapped.kind == FacebookApiErrorKind.unknown &&
          e.response?.statusCode == 400) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.insightsUnavailable,
          message:
              'Meta reports these Page metrics are unavailable. The metric '
              'names may have changed.',
          code: mapped.code,
          subcode: mapped.subcode,
        );
      }
      throw mapped;
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Could not load Page performance.',
      );
    }
  }

  static FacebookPageInsights _parse(
    Map<String, dynamic> body,
    String pageId,
    DateTime fetchedAt,
  ) {
    final rows = body['data'];
    if (rows is! List) {
      return FacebookPageInsights(
        pageId: pageId,
        points: const [],
        fetchedAt: fetchedAt,
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
