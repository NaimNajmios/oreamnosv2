import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_monetization.dart';
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
    try {
      final response = await _client.get<dynamic>(
        '$_pathBase/${Uri.encodeComponent(pageId)}/insights',
        queryParameters: {
          'metric': [
            FacebookMetricNames.contentMonetizationEarnings,
            FacebookMetricNames.monetizationApproximateEarnings,
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
        action: 'monetization earnings',
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
      FacebookDiagnostics.failure(
        'Monetization earnings',
        mapped,
        statusCode: e.response?.statusCode,
      );
      if (mapped.kind == FacebookApiErrorKind.unknown &&
          e.response?.statusCode == 400) {
        throw FacebookApiException(
          kind: FacebookApiErrorKind.insightsUnavailable,
          message:
              'Meta reports monetization insights are unavailable for this '
              'Page. Confirm Content Monetization enrollment.',
          code: mapped.code,
          subcode: mapped.subcode,
        );
      }
      throw mapped;
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Could not load estimated earnings.',
      );
    }
  }

  static FacebookMonetizationSnapshot _parse(
    Map<String, dynamic> body,
    String pageId,
    DateTime fetchedAt,
  ) {
    double? total(String name) {
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

    return FacebookMonetizationSnapshot(
      pageId: pageId,
      totalEarnings: total(FacebookMetricNames.contentMonetizationEarnings),
      totalApproximateEarnings: total(
        FacebookMetricNames.monetizationApproximateEarnings,
      ),
      fetchedAt: fetchedAt,
      currency: '',
    );
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
