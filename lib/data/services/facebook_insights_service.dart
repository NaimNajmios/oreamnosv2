import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import '../../domain/models/facebook_post_insights.dart';

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
      final response = await _client.get<Map<String, dynamic>>(
        '$_pathBase/${Uri.encodeComponent(postId)}',
        queryParameters: const {
          'fields':
              'insights.metric('
              'post_impressions_unique,post_reactions_by_type_total,'
              'post_clicks)',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = _asMap(response.data);
      return _parse(data, DateTime.now());
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      throw FacebookApiException.fromGraph(
        e.response?.statusCode,
        _asMap(e.response?.data),
        isNetworkFailure: e.response == null,
      );
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.insightsUnavailable,
        message: 'Insights are unavailable for this post.',
      );
    }
  }

  static FacebookPostInsights _parse(
    Map<String, dynamic>? body,
    DateTime fetchedAt,
  ) {
    final insights = body?['insights'];
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

    int? reactions() {
      final values = metrics['post_reactions_by_type_total'];
      if (values is! List || values.isEmpty) return null;
      final first = values.first;
      final value = first is Map ? first['value'] : first;
      if (value is! Map) return _asInt(value);
      var sum = 0;
      var found = false;
      for (final entry in value.values) {
        final count = _asInt(entry);
        if (count != null) {
          sum += count;
          found = true;
        }
      }
      return found ? sum : null;
    }

    return FacebookPostInsights(
      impressions: single('post_impressions_unique'),
      reactions: reactions(),
      clicks: single('post_clicks'),
      fetchedAt: fetchedAt,
    );
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
