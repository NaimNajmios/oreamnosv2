import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../../../data/services/facebook_publisher_service.dart';
import '../../../../data/services/facebook_history_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/facebook_api_exception.dart';
import '../../../../domain/services/facebook_text_formatter.dart';
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

final facebookDraftProvider =
    NotifierProvider<FacebookDraftNotifier, FacebookComposeState>(
      () => FacebookDraftNotifier(),
    );

/// Compose-screen draft: seeded by the Generate / Card Generator entry
/// points via [startDraft], then edited freely. `startDraft` strips the
/// TypewriterMarkdown syntax up front so the feed never sees `**bold**` or
/// `[links](…)`.
class FacebookDraftNotifier extends Notifier<FacebookComposeState> {
  late final FacebookPublisherService _publisher;
  late final PreferencesService _preferencesService;

  @override
  FacebookComposeState build() {
    _publisher = getIt<FacebookPublisherService>();
    _preferencesService = getIt<PreferencesService>();
    return const FacebookComposeState();
  }

  /// Entry point for the publish icons. Keeps the router free of `extra`:
  /// screens seed the draft first, then push `/facebook-compose`.
  void startDraft(String rawMarkdown, {String? imagePath}) {
    state = FacebookComposeState(
      text: FacebookTextFormatter.toPlainText(rawMarkdown),
      imagePath: imagePath,
    );
  }

  void setDraftText(String value) {
    state = state.copyWith(text: value);
  }

  void clearDraft() {
    state = const FacebookComposeState();
  }

  /// Gallery or camera pick; free downscaling via ImagePicker's
  /// `maxWidth`/`imageQuality`, no extra package. Returns false on cancel
  /// or failure (no error panel — picking is best-effort).
  Future<bool> attachImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (picked == null) return false;
      state = state.copyWith(imagePath: picked.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  void removeImage() {
    state = state.copyWith(imagePath: null);
  }

  /// Publishes the draft. Text posts go to `/{page}/feed`; drafts with an
  /// attachment go to `/{page}/photos`. Returns the disconnected caller
  /// with either a [FacebookComposePhase.published] result or a
  /// [FacebookComposePhase.publishError] carrying the mapped exception.
  Future<void> publish() async {
    if (state.isPublishing || !state.hasText) return;
    state = state.copyWith(phase: FacebookComposePhase.publishing, error: null);

    if (!await _rawIsOnline()) {
      state = state.copyWith(
        phase: FacebookComposePhase.publishError,
        error: const FacebookApiException(
          kind: FacebookApiErrorKind.network,
          message: 'No connection. Check your internet and try again.',
        ),
      );
      return;
    }

    final conn = ref.read(facebookViewModelProvider);
    final pageId = conn.pageId;
    final token = await _preferencesService.getFacebookPageToken() ?? '';
    if (pageId.isEmpty || token.isEmpty) {
      state = state.copyWith(
        phase: FacebookComposePhase.publishError,
        error: const FacebookApiException(
          kind: FacebookApiErrorKind.unknown,
          message: 'Connect your Page before publishing.',
        ),
      );
      return;
    }

    try {
      final image = state.imagePath;
      final result = image != null
          ? await _publisher.publishPhoto(
              pageId: pageId,
              token: token,
              filePath: image,
              message: state.text,
            )
          : await _publisher.publishText(
              pageId: pageId,
              token: token,
              message: state.text,
            );
      state = state.copyWith(
        phase: FacebookComposePhase.published,
        result: result,
      );
      // Persist for the Published Posts history (Stage 4).
      try {
        if (getIt.isRegistered<FacebookHistoryService>()) {
          await getIt<FacebookHistoryService>().recordPublish(
            postId: result.postId,
            message: state.text,
            permalink: result.permalink,
            hasImage: result.isPhoto || state.imagePath != null,
          );
        }
      } catch (_) {}
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) {
        ref.read(facebookViewModelProvider.notifier).markExpired();
      }
      state = state.copyWith(
        phase: FacebookComposePhase.publishError,
        error: e,
      );
    } catch (_) {
      state = state.copyWith(
        phase: FacebookComposePhase.publishError,
        error: const FacebookApiException(
          kind: FacebookApiErrorKind.unknown,
          message: 'Publishing failed unexpectedly. Try again.',
        ),
      );
    }
  }

  /// Lightweight offline probe (no connectivity_* dependency): resolves the
  /// Graph host before spending an attempt. Best-effort — real failures
  /// still surface as network errors from the request itself.
  static bool Function()? onlineProbeOverride;

  static Future<bool> _rawIsOnline() async {
    final override = onlineProbeOverride;
    if (override != null) return Future.value(override());
    try {
      final addresses = await InternetAddress.lookup('graph.facebook.com');
      return addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return true;
    }
  }
}
