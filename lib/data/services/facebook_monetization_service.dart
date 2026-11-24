import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_monetization.dart';
import 'preferences_service.dart';
import 'facebook_diagnostics.dart';
import 'facebook_metric_names.dart';
import 'facebook_network_error.dart';
import 'facebook_response_guard.dart';

/// Content Monetization earnings. Page-level only; per-post values are
/// lifetime totals and must never be summed across dates.
@lazySingleton
class FacebookMonetizationService {
  FacebookMonetizationService([ApiClient? client])
    : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  String get _pathBase =>
      '${AppConstants.facebookGraphBaseUrl}/'
      '${AppConstants.facebookGraphVersion}';

  Future<FacebookMonetizationSnapshot> fetch({
    required String pageId,
    required String token,
    int days = 28,
  }) async {
    if (pageId.trim().isEmpty || token.trim().isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.permission,
        message: 'Connect your Page to load estimated earnings.',
      );
    }
    final until = DateTime.now();
    final since = until.subtract(Duration(days: days));
    final sinceSeconds = '${since.toUtc().millisecondsSinceEpoch ~/ 1000}';
    final untilSeconds = '${until.toUtc().millisecondsSinceEpoch ~/ 1000}';

    // One request per metric: a 400 rejects the whole call.
    var totalEarnings = 0.0;
    var totalApproximateEarnings = 0.0;
    var found = false;
    try {
      for (final metric in [
        FacebookMetricNames.contentMonetizationEarnings,
        FacebookMetricNames.monetizationApproximateEarnings,
      ]) {
        final data = await _getMetric(
          pageId,
          token,
          metric,
          sinceSeconds,
          untilSeconds,
        );
        final total = _total(data, metric);
        if (total != null) {
          found = true;
          if (metric == FacebookMetricNames.contentMonetizationEarnings) {
            totalEarnings += total;
          } else {
            totalApproximateEarnings += total;
          }
        }
      }
    } catch (e) {
      if (e is FacebookApiException && e.code == 400) {
        return _markNotAvailable(pageId);
      }
      rethrow;
    }
    return FacebookMonetizationSnapshot(
      pageId: pageId,
      totalEarnings: found ? totalEarnings : null,
      totalApproximateEarnings: found ? totalApproximateEarnings : null,
      fetchedAt: DateTime.now(),
      currency: '',
    );
  }

  Future<Map<String, dynamic>> _getMetric(
    String pageId,
    String token,
    String metric,
    String sinceSeconds,
    String untilSeconds,
  ) async {
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(pageId)}/insights',
        queryParameters: {
          'metric': metric,
          'period': 'day',
          'since': sinceSeconds,
          'until': untilSeconds,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: AppConstants.facebookWriteTimeout,
        ),
      );
      return facebookRequireObject(
        response.data,
        action: 'monetization earnings',
      );
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      final mapped = FacebookApiException.fromGraph(
        e.response?.statusCode,
        _asMap(e.response?.data),
        isNetworkFailure: e.response == null,
        networkIssue: e.response == null ? facebookNetworkIssueFor(e) : null,
      );
      if (mapped.kind == FacebookApiErrorKind.unknown &&
          (e.response?.statusCode == 400 || mapped.code == 100)) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.insightsUnavailable,
          message: FacebookDiagnostics.metaReason(mapped.graphMessage),
          code: mapped.code,
          subcode: mapped.subcode,
          traceId: mapped.traceId,
        );
      }
      FacebookDiagnostics.failure(
        'Monetization earnings',
        mapped,
        statusCode: e.response?.statusCode,
        pageId: pageId,
      );
      throw mapped;
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Could not load estimated earnings.',
      );
    }
  }

  /// Caches "not available for this Page" for 24 hours and logs the
  /// negative outcome at WARN rather than ERROR (plan expects the request
  /// to be skipped again before that).
  Future<FacebookMonetizationSnapshot> _markNotAvailable(String pageId) async {
    final prefs = getIt<PreferencesService>();
    await prefs.setFacebookMonetizationUnavailableUntil(
      DateTime.now().add(const Duration(hours: 24)),
    );
    FacebookDiagnostics.warning(
      'Monetization earnings unavailable for this Page',
      const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Not enrolled for Content Monetization.',
      ),
      pageId: pageId,
    );
    return FacebookMonetizationSnapshot(
      pageId: pageId,
      totalEarnings: null,
      totalApproximateEarnings: null,
      fetchedAt: DateTime.now(),
      currency: '',
    );
  }

  static double? _total(Map<String, dynamic> body, String name) {
    final rows = body['data'];
    if (rows is! List) return null;
    var found = false;
    var sum = 0.0;
    for (final row in rows) {
      if (row is! Map || row['name']?.toString() != name) continue;
      final values = row['values'];
      if (values is! List) continue;
      for (final entry in values) {
        if (entry is! Map) continue;
        final value = _asDouble(entry['value']);
        if (value == null) continue;
        found = true;
        sum += value;
      }
    }
    return found ? sum : null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
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
