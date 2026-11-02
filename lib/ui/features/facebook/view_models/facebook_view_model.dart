import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../../../data/services/facebook_publisher_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/facebook_api_exception.dart';
import 'facebook_state.dart';

final facebookViewModelProvider =
    NotifierProvider<FacebookNotifier, FacebookUiState>(
      () => FacebookNotifier(),
    );

/// Tracks the Facebook Page connection (Stage 2) and, from Stage 3 on,
/// drives the compose screen draft + publish flow.
class FacebookNotifier extends Notifier<FacebookUiState> {
  late final PreferencesService _preferencesService;
  late final FacebookPublisherService _publisher;

  @override
  FacebookUiState build() {
    _preferencesService = getIt<PreferencesService>();
    _publisher = getIt<FacebookPublisherService>();
    final pageId = _preferencesService.facebookPageId ?? '';
    final pageName = _preferencesService.facebookPageName ?? '';
    // Expired status starts as connected: only a failed publish (190)
    // marks it expired, and the next publish should try again first.
    return FacebookUiState(
      status: pageId.isEmpty
          ? FacebookConnectionStatus.notConnected
          : FacebookConnectionStatus.connected,
      pageId: pageId,
      pageName: pageName,
    );
  }

  /// Verifies the pasted Page token against `GET /me` and persists the
  /// connection ONLY after verification succeeds (token in secure storage,
  /// Page id/name in prefs). Returns null on success, otherwise the
  /// human-readable error message for the dialog to show inline.
  Future<String?> connect(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return 'Paste a Page access token first.';
    try {
      final page = await _publisher.verify(trimmed);
      await _preferencesService.setFacebookPageToken(trimmed);
      await _preferencesService.setFacebookPageId(page.id);
      await _preferencesService.setFacebookPageName(page.name);
      state = FacebookUiState(
        status: FacebookConnectionStatus.connected,
        pageId: page.id,
        pageName: page.name,
      );
      return null;
    } on FacebookApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Connection failed. Double-check the token and try again.';
    }
  }

  /// Removes the token, Page identity and publish history.
  Future<void> disconnect() async {
    await _preferencesService.disconnectFacebook();
    state = const FacebookUiState();
  }

  /// Marks the stored token as expired after a 190 publish failure; the
  /// compose screen then offers Reconnect instead of plain Retry.
  void markExpired() {
    if (state.status == FacebookConnectionStatus.connected) {
      state = state.copyWith(status: FacebookConnectionStatus.expired);
    }
  }
}
