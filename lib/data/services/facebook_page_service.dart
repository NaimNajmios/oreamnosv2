import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_api_exception.dart';
import 'facebook_publisher_service.dart';

/// A Page returned by `/me/accounts` plus its derived token.
///
/// The token is only ever held in memory long enough to persist it under
/// `facebook_page_token_<pageId>`; the user token is never retained.
class FacebookPageAccount {
  const FacebookPageAccount({required this.page, required this.pageToken});

  final FacebookPage page;
  final String pageToken;
}

/// Verifies Page tokens and exchanges a user token for Page tokens.
@lazySingleton
class FacebookPageService {
  FacebookPageService([ApiClient? client, FacebookPublisherService? publisher])
    : _client = client ?? getIt<ApiClient>(),
      _publisher = publisher ?? getIt<FacebookPublisherService>();

  final ApiClient _client;
  final FacebookPublisherService _publisher;

  String get _pathBase =>
      '${AppConstants.facebookGraphBaseUrl}/'
      '${AppConstants.facebookGraphVersion}';

  Future<FacebookPage> verifyPageToken(String token) =>
      _publisher.verify(token);

  /// `GET /me/accounts` with a user token. Skips rows without an id/token.
  Future<List<FacebookPageAccount>> listPagesFromUserToken(
    String userToken,
  ) async {
    final token = userToken.trim();
    if (token.isEmpty) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.pageTokenExchangeFailed,
        message: 'Paste a user access token first.',
      );
    }
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '$_pathBase/me/accounts',
        queryParameters: const {
          'fields': 'id,name,access_token,picture{url}',
          'limit': 100,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = _asMap(response.data);
      final rows = data?['data'];
      if (rows is! List) {
        throw const FacebookApiException(
          kind: FacebookApiErrorKind.pageTokenExchangeFailed,
          message:
              'Facebook returned no Pages. Make sure this token has '
              'pages_show_list and manage_pages permissions.',
        );
      }
      final accounts = <FacebookPageAccount>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final id = row['id']?.toString() ?? '';
        final pageToken = row['access_token']?.toString() ?? '';
        if (id.isEmpty || pageToken.isEmpty) continue;
        accounts.add(
          FacebookPageAccount(
            page: FacebookPage(
              id: id,
              name: row['name']?.toString() ?? '',
              pictureUrl: _pictureUrl(row),
            ),
            pageToken: pageToken,
          ),
        );
      }
      if (accounts.isEmpty) {
        throw const FacebookApiException(
          kind: FacebookApiErrorKind.pageTokenExchangeFailed,
          message:
              'No Pages were returned for this token. Check the account has '
              'a Facebook Page and that pages_show_list is granted.',
        );
      }
      return accounts;
    } on FacebookApiException {
      rethrow;
    } on DioException catch (e) {
      final mapped = FacebookApiException.fromGraph(
        e.response?.statusCode,
        _asMap(e.response?.data),
        isNetworkFailure: e.response == null,
      );
      if (e.response == null) throw mapped;
      throw FacebookApiException(
        kind: mapped.kind == FacebookApiErrorKind.expiredToken
            ? FacebookApiErrorKind.expiredToken
            : FacebookApiErrorKind.pageTokenExchangeFailed,
        message: mapped.kind == FacebookApiErrorKind.expiredToken
            ? mapped.message
            : 'Could not read Pages from this token. Make sure it was '
                  'created with pages_show_list and manage_pages.',
        code: mapped.code,
        subcode: mapped.subcode,
      );
    } catch (_) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.pageTokenExchangeFailed,
        message: 'Could not connect Pages. Try again.',
      );
    }
  }

  static String _pictureUrl(Map row) {
    final picture = row['picture'];
    if (picture is! Map) return '';
    final nested = picture['data'];
    if (nested is Map) return (nested['url'] ?? '').toString();
    return '';
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
