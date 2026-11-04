import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/services/facebook_page_service.dart';
import '../../../../data/services/facebook_image_cropper.dart';
import '../../../../data/services/facebook_publisher_service.dart';
import '../../../../data/services/facebook_history_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/facebook_api_exception.dart';
import '../../../../domain/models/facebook_post_record.dart';
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
  late final FacebookPageService _pageService;

  @override
  FacebookUiState build() {
    _preferencesService = getIt<PreferencesService>();
    _pageService = getIt<FacebookPageService>();
    final pages = _preferencesService.facebookPages;
    var activeId = _preferencesService.facebookActivePageId ?? '';
    if (activeId.isEmpty && pages.isNotEmpty) activeId = pages.first.id;
    if (activeId.isEmpty) {
      activeId = _preferencesService.facebookPageId ?? '';
    }
    final effectivePages = pages.isNotEmpty
        ? pages
        : activeId.isEmpty
        ? const <FacebookPage>[]
        : [
            FacebookPage(
              id: activeId,
              name: _preferencesService.facebookPageName ?? '',
              pictureUrl: _preferencesService.facebookPagePicture ?? '',
            ),
          ];
    final active = _findPage(effectivePages, activeId);
    unawaited(_migrateAndRefresh());
    // Expired status starts as connected: only a failed publish (190)
    // marks it expired, and the next publish should try again first.
    return FacebookUiState(
      status: activeId.isEmpty
          ? FacebookConnectionStatus.notConnected
          : FacebookConnectionStatus.connected,
      pageId: active?.id ?? activeId,
      pageName: active?.name ?? _preferencesService.facebookPageName ?? '',
      pagePictureUrl:
          active?.pictureUrl ??
          _preferencesService.facebookPagePicture ??
          '',
      pages: effectivePages,
      activePageId: activeId,
    );
  }

  Future<void> _migrateAndRefresh() async {
    try {
      await _preferencesService.migrateLegacyFacebookPage();
      _syncFromStorage();
    } catch (_) {}
  }

  void _syncFromStorage() {
    final pages = _preferencesService.facebookPages;
    final activeId = _preferencesService.facebookActivePageId ?? '';
    final active = _findPage(pages, activeId);
    state = FacebookUiState(
      status: activeId.isEmpty || active == null
          ? FacebookConnectionStatus.notConnected
          : FacebookConnectionStatus.connected,
      pageId: active?.id ?? '',
      pageName: active?.name ?? '',
      pagePictureUrl: active?.pictureUrl ?? '',
      pages: pages,
      activePageId: activeId,
    );
  }

  static FacebookPage? _findPage(List<FacebookPage> pages, String id) {
    for (final page in pages) {
      if (page.id == id) return page;
    }
    return null;
  }

  Future<void> _activate(FacebookPage page) async {
    await _preferencesService.setFacebookActivePageId(page.id);
    await _preferencesService.setFacebookPageId(page.id);
    await _preferencesService.setFacebookPageName(page.name);
    if (page.pictureUrl.isNotEmpty) {
      await _preferencesService.setFacebookPagePicture(page.pictureUrl);
    }
    final pages = _preferencesService.facebookPages;
    state = FacebookUiState(
      status: FacebookConnectionStatus.connected,
      pageId: page.id,
      pageName: page.name,
      pagePictureUrl: page.pictureUrl,
      pages: pages,
      activePageId: page.id,
    );
  }

  /// Verifies the pasted Page token against `GET /me` and persists the
  /// connection ONLY after verification succeeds (token in secure storage,
  /// Page id/name in prefs). Returns null on success, otherwise the
  /// human-readable error message for the dialog to show inline.
  Future<String?> connect(String token) => connectPageToken(token);

  Future<String?> connectPageToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return 'Paste a Page access token first.';
    try {
      final page = await _publisher.verify(trimmed);
      await _preferencesService.setFacebookPageTokenFor(page.id, trimmed);
      await _preferencesService.upsertFacebookPage(page);
      await _activate(page);
      return null;
    } on FacebookApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Connection failed. Double-check the token and try again.';
    }
  }

  /// Exchanges a user token for Page tokens. Only the derived Page tokens
  /// are persisted; the user token is discarded immediately.
  Future<String?> connectWithUserToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return 'Paste a user access token first.';
    try {
      final accounts = await _pageService.listPagesFromUserToken(trimmed);
      final merged = [..._preferencesService.facebookPages];
      for (final account in accounts) {
        await _preferencesService.setFacebookPageTokenFor(
          account.page.id,
          account.pageToken,
        );
        final index = merged.indexWhere((p) => p.id == account.page.id);
        if (index < 0) {
          merged.add(account.page);
        } else {
          merged[index] = account.page;
        }
      }
      await _preferencesService.setFacebookPages(merged);
      await _activate(accounts.first.page);
      return null;
    } on FacebookApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not connect Pages. Try again.';
    }
  }

  /// Switches the active Page. Draft ownership is guarded in the composer.
  Future<void> switchPage(String pageId) async {
    final page = _findPage(state.pages, pageId);
    if (page == null || page.id == state.activePageId) return;
    await _activate(page);
  }

  /// Disconnects only the active Page. Other Pages and their tokens remain.
  Future<void> disconnectActivePage() async {
    final id = state.activePageId;
    if (id.isEmpty) return;
    await _preferencesService.disconnectFacebookPage(id);
    _syncFromStorage();
  }

  /// Removes tokens, Page identities, publish history and drafts.
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
///
/// Edits are autosaved (debounced) to prefs and restored on the next build,
/// so an accidental back gesture never loses a long caption. Publishing or
/// discarding clears the saved snapshot.
class FacebookDraftNotifier extends Notifier<FacebookComposeState> {
  static const Duration _autosaveDebounce = Duration(milliseconds: 500);

  /// Graph's scheduling window: 10 minutes from now, up to 30 days.
  static const Duration minScheduleLead = Duration(minutes: 10);
  static const Duration maxScheduleLead = Duration(days: 30);

  late final FacebookPublisherService _publisher;
  late final PreferencesService _preferencesService;
  Timer? _autosaveTimer;

  @override
  FacebookComposeState build() {
    _publisher = getIt<FacebookPublisherService>();
    _preferencesService = getIt<PreferencesService>();
    ref.onDispose(() => _autosaveTimer?.cancel());
    final saved = _restoreDraft();
    return saved ?? const FacebookComposeState();
  }

  FacebookComposeState? _restoreDraft() {
    final raw = _preferencesService.facebookDraftJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final snapshot = FacebookDraftSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (snapshot.isEmpty) return null;
      return FacebookComposeState(
        text: snapshot.text,
        media: snapshot.media,
        publishMode: snapshot.publishMode,
        scheduledAt: snapshot.scheduledAt,
        restoredFromStorage: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Entry point for the publish icons. Keeps the router free of `extra`:
  /// screens seed the draft first, then push `/facebook-compose`.
  void startDraft(
    String rawMarkdown, {
    String? imagePath,
    FacebookImageAspect? imageAspect,
  }) {
    state = FacebookComposeState(
      text: FacebookTextFormatter.toPlainText(rawMarkdown),
      media: [
        if (imagePath != null && imagePath.isNotEmpty)
          FacebookMediaItem(
            id: _newMediaId(),
            path: imagePath,
            aspect: imageAspect ?? FacebookImageAspect.portrait,
          ),
      ],
    );
    _scheduleAutosave();
  }

  void setDraftText(String value) {
    state = state.copyWith(text: value, restoredFromStorage: false);
    _scheduleAutosave();
  }

  void setPublishMode(FacebookPublishMode mode) {
    if (state.publishMode == mode) return;
    state = state.copyWith(
      publishMode: mode,
      scheduledAt: mode == FacebookPublishMode.now ? null : state.scheduledAt,
    );
    _scheduleAutosave();
  }

  void setScheduledAt(DateTime? value) {
    state = state.copyWith(
      scheduledAt: value,
      publishMode: value == null
          ? FacebookPublishMode.now
          : FacebookPublishMode.scheduled,
    );
    _scheduleAutosave();
  }

  /// Appends the default hashtag group when it isn't already present.
  /// Returns false when there is nothing configured to append.
  bool appendDefaultHashtags() {
    final hashtags = _preferencesService.defaultHashtags.trim();
    if (hashtags.isEmpty) return false;
    final current = state.text.trimRight();
    if (current.contains(hashtags)) return true;
    final next = current.isEmpty ? hashtags : '$current\n\n$hashtags';
    state = state.copyWith(text: next);
    _scheduleAutosave();
    return true;
  }

  void clearDraft() {
    _autosaveTimer?.cancel();
    state = const FacebookComposeState();
    unawaited(_preferencesService.clearFacebookDraft());
  }

  /// "Publish another" — keeps the connection, resets text + attachment.
  void resetForAnotherPost() {
    state = const FacebookComposeState();
    unawaited(_preferencesService.clearFacebookDraft());
  }

  /// Saves the current draft to prefs after a short idle period.
  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDebounce, () {
      if (state.isFinished) return;
      final snapshot = FacebookDraftSnapshot(
        text: state.text,
        media: state.media,
        publishMode: state.publishMode,
        scheduledAt: state.scheduledAt,
      );
      if (snapshot.isEmpty) {
        unawaited(_preferencesService.clearFacebookDraft());
      } else {
        unawaited(
          _preferencesService.setFacebookDraftJson(
            jsonEncode(snapshot.toJson()),
          ),
        );
      }
    });
  }

  /// Gallery pick for one or more photos (cap 4). Returns how many were added.
  Future<int> attachImages(ImageSource source) async {
    if (!state.canAddMoreMedia) return 0;
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (files.isEmpty) return 0;
      final slots = FacebookLimits.maxPhotos - state.media.length;
      final aspect = state.mediaItem?.aspect ?? FacebookImageAspect.portrait;
      final added = files
          .take(slots)
          .map(
            (file) => FacebookMediaItem(
              id: _newMediaId(),
              path: file.path,
              aspect: aspect,
            ),
          )
          .toList();
      if (added.isEmpty) return 0;
      state = state.copyWith(
        media: [...state.media, ...added],
        restoredFromStorage: false,
      );
      _scheduleAutosave();
      return added.length;
    } catch (_) {
      return 0;
    }
  }

  /// Camera pick — replaces the current photos with a single new capture.
  Future<bool> attachImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (picked == null) return false;
      final existing = state.mediaItem;
      state = state.copyWith(
        media: [
          FacebookMediaItem(
            id: _newMediaId(),
            path: picked.path,
            aspect: existing?.aspect ?? FacebookImageAspect.portrait,
          ),
        ],
        restoredFromStorage: false,
      );
      _scheduleAutosave();
      return true;
    } catch (_) {
      return false;
    }
  }

  void removeMedia(String id) {
    final next = state.media
        .where((item) => item.identity != id)
        .toList(growable: false);
    state = state.copyWith(media: next, restoredFromStorage: false);
    _scheduleAutosave();
  }

  void removeImage() {
    state = state.copyWith(media: const [], restoredFromStorage: false);
    _scheduleAutosave();
  }

  /// Moves a photo within the carousel (and therefore the published order).
  void moveMedia(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= state.media.length ||
        to >= state.media.length ||
        from == to) {
      return;
    }
    final next = List<FacebookMediaItem>.of(state.media);
    final item = next.removeAt(from);
    next.insert(to, item);
    state = state.copyWith(media: next, restoredFromStorage: false);
    _scheduleAutosave();
  }

  /// Cover = first photo in the carousel / feed.
  void makeCover(String id) {
    final index = state.media.indexWhere((item) => item.identity == id);
    if (index <= 0) return;
    moveMedia(index, 0);
  }

  void setImageAspect(FacebookImageAspect aspect) {
    final item = state.mediaItem;
    if (item == null || item.aspect == aspect) return;
    _updateMedia(item.copyWith(aspect: aspect));
  }

  /// Pan/zoom from the composer preview. [zoom] is clamped to 1–4 and
  /// [offset] to the normalized -1..1 range understood by the cropper.
  void setMediaCrop({required double zoom, required Offset offset}) {
    final item = state.mediaItem;
    if (item == null) return;
    _updateMedia(
      item.copyWith(
        zoom: zoom.clamp(1.0, 4.0).toDouble(),
        offset: Offset(
          offset.dx.clamp(-1.0, 1.0).toDouble(),
          offset.dy.clamp(-1.0, 1.0).toDouble(),
        ),
      ),
    );
  }

  /// Updates one carousel photo by id (used by the Edit photo sheet).
  void updateMedia(
    String id, {
    FacebookImageAspect? aspect,
    double? zoom,
    Offset? offset,
    String? altText,
  }) {
    final item = state.mediaById(id);
    if (item == null) return;
    _updateMedia(
      item.copyWith(
        aspect: aspect,
        zoom: zoom?.clamp(1.0, 4.0).toDouble(),
        offset: offset == null
            ? null
            : Offset(
                offset.dx.clamp(-1.0, 1.0).toDouble(),
                offset.dy.clamp(-1.0, 1.0).toDouble(),
              ),
        altText: altText,
      ),
    );
  }

  void resetCrop() {
    final item = state.mediaItem;
    if (item == null) return;
    _updateMedia(item.copyWith(zoom: 1.0, offset: Offset.zero));
  }

  void resetMediaCrop(String id) {
    updateMedia(id, zoom: 1.0, offset: Offset.zero);
  }

  void setAltText(String value) {
    final item = state.mediaItem;
    if (item == null || item.altText == value) return;
    _updateMedia(item.copyWith(altText: value));
  }

  void _updateMedia(FacebookMediaItem item) {
    state = state.copyWith(
      media: state.media
          .map((m) => m.identity == item.identity ? item : m)
          .toList(growable: false),
      restoredFromStorage: false,
    );
    _scheduleAutosave();
  }

  static String _newMediaId() => const Uuid().v4();

  /// Validates the scheduling window. Returns null when OK, otherwise the
  /// user-facing reason.
  static String? scheduleValidationError(DateTime at, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (at.isBefore(current.add(minScheduleLead))) {
      return 'Choose a time at least 10 minutes from now.';
    }
    if (at.isAfter(current.add(maxScheduleLead))) {
      return 'Facebook only schedules up to 30 days ahead.';
    }
    return null;
  }

  /// Publishes the draft. Text posts go to `/{page}/feed`; drafts with an
  /// attachment go to `/{page}/photos`. Returns the caller with either a
  /// [FacebookComposePhase.published]/[FacebookComposePhase.scheduled]
  /// result or a [FacebookComposePhase.publishError].
  Future<void> publish() async {
    if (state.isPublishing || state.isFinished || !state.hasText) return;

    final scheduled = state.publishMode == FacebookPublishMode.scheduled;
    final scheduledAt = state.scheduledAt;
    if (scheduled) {
      if (scheduledAt == null) {
        _fail('Pick a date and time to schedule this post.');
        return;
      }
      final validation = scheduleValidationError(scheduledAt);
      if (validation != null) {
        _fail(validation);
        return;
      }
    }

    // A card captured in Card Studio lives in the temp dir, which the OS
    // may purge. Fail with a fixable message instead of a Graph error.
    final mediaItems = state.media;
    for (final item in mediaItems) {
      if (!File(item.path).existsSync()) {
        _fail(
          'The attached image is no longer available. Re-attach it and try again.',
        );
        return;
      }
    }

    state = state.copyWith(
      phase: FacebookComposePhase.publishing,
      uploadProgress: mediaItems.isEmpty ? null : 0.0,
      error: null,
      restoredFromStorage: false,
    );

    if (!await _rawIsOnline()) {
      _fail(
        'No connection. Check your internet and try again.',
        kind: FacebookApiErrorKind.network,
      );
      return;
    }

    final conn = ref.read(facebookViewModelProvider);
    final pageId = conn.pageId;
    final token = await _preferencesService.getFacebookPageToken() ?? '';
    if (pageId.isEmpty || token.isEmpty) {
      _fail('Connect your Page before publishing.');
      return;
    }

    try {
      late FacebookPublishResult result;
      if (mediaItems.isEmpty) {
        result = await _publisher.publishText(
          pageId: pageId,
          token: token,
          message: state.text,
          scheduledAt: scheduled ? scheduledAt : null,
        );
      } else if (mediaItems.length == 1) {
        final media = mediaItems.single;
        final uploadPath = await _cropForUpload(media);
        result = await _publisher.publishPhoto(
          pageId: pageId,
          token: token,
          filePath: uploadPath,
          message: state.text,
          altText: media.altText,
          scheduledAt: scheduled ? scheduledAt : null,
          onSendProgress: (sent, total) {
            if (!state.isPublishing || total <= 0) return;
            state = state.copyWith(
              uploadProgress: (sent / total).clamp(0.0, 1.0),
            );
          },
        );
      } else {
        result = await _publishMultiple(
          pageId: pageId,
          token: token,
          media: mediaItems,
          scheduledAt: scheduled ? scheduledAt : null,
        );
      }
      state = state.copyWith(
        phase: scheduled
            ? FacebookComposePhase.scheduled
            : FacebookComposePhase.published,
        uploadProgress: null,
        result: result,
      );
      _autosaveTimer?.cancel();
      unawaited(_preferencesService.clearFacebookDraft());
      // Persist for the Published / Scheduled history.
      try {
        if (getIt.isRegistered<FacebookHistoryService>()) {
          await getIt<FacebookHistoryService>().recordPublish(
            postId: result.postId,
            message: state.text,
            permalink: result.permalink,
            hasImage: result.isPhoto || state.hasImage,
            sourceImagePaths: state.media.map((m) => m.path).toList(),
            status: scheduled
                ? FacebookPostStatus.scheduled
                : FacebookPostStatus.published,
            scheduledAt: scheduled ? scheduledAt : null,
            pageId: pageId,
            pageName: conn.pageName,
          );
        }
      } catch (_) {}
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) {
        ref.read(facebookViewModelProvider.notifier).markExpired();
      }
      state = state.copyWith(
        phase: FacebookComposePhase.publishError,
        uploadProgress: null,
        error: e,
      );
    } catch (_) {
      _fail('Publishing failed unexpectedly. Try again.');
    }
  }

  /// Uploads every photo unpublished, then creates one feed post. Any
  /// failure aborts before the feed post and deletes uploaded photos.
  Future<FacebookPublishResult> _publishMultiple({
    required String pageId,
    required String token,
    required List<FacebookMediaItem> media,
    DateTime? scheduledAt,
  }) async {
    final photoIds = <String>[];
    try {
      for (var i = 0; i < media.length; i++) {
        final item = media[i];
        final uploadPath = await _cropForUpload(item);
        final id = await _publisher.uploadUnpublishedPhoto(
          pageId: pageId,
          token: token,
          filePath: uploadPath,
          altText: item.altText,
          onSendProgress: (sent, total) {
            if (!state.isPublishing || total <= 0) return;
            final current = total <= 0 ? 0.0 : (sent / total).clamp(0.0, 1.0);
            state = state.copyWith(
              uploadProgress: ((i + current) / media.length).clamp(0.0, 1.0),
            );
          },
        );
        photoIds.add(id);
      }
      return await _publisher.publishMultiPhoto(
        pageId: pageId,
        token: token,
        photoIds: photoIds,
        message: state.text,
        scheduledAt: scheduledAt,
      );
    } catch (e) {
      for (final id in photoIds) {
        await _publisher.deletePhoto(photoId: id, token: token);
      }
      rethrow;
    }
  }

  void _fail(String message, {FacebookApiErrorKind? kind}) {
    state = state.copyWith(
      phase: FacebookComposePhase.publishError,
      uploadProgress: null,
      error: FacebookApiException(
        kind: kind ?? FacebookApiErrorKind.unknown,
        message: message,
      ),
    );
  }

  Future<String> _cropForUpload(FacebookMediaItem media) async {
    try {
      final dir = await getTemporaryDirectory();
      final cropped = await FacebookImageCropper.cropToFile(
        sourcePath: media.path,
        targetAspect: media.aspect.ratio,
        outputDir: dir.path,
        zoom: media.zoom,
        offset: media.offset,
      );
      return cropped ?? media.path;
    } catch (_) {
      return media.path;
    }
  }

  /// Cancels a scheduled post on Graph and drops the local history row.
  /// Returns null on success, otherwise a user-facing error.
  Future<String?> cancelScheduledPost(String postId) async {
    final token = await _preferencesService.getFacebookPageToken() ?? '';
    if (token.isEmpty) return 'Connect your Page first.';
    try {
      await _publisher.cancelScheduled(postId: postId, token: token);
      try {
        if (getIt.isRegistered<FacebookHistoryService>()) {
          await getIt<FacebookHistoryService>().removeByPostId(postId);
        }
      } catch (_) {}
      return null;
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) {
        ref.read(facebookViewModelProvider.notifier).markExpired();
      }
      return e.message;
    } catch (_) {
      return 'Could not cancel the scheduled post.';
    }
  }

  /// Moves a scheduled post and keeps the local record in sync.
  Future<String?> reschedulePost(String postId, DateTime scheduledAt) async {
    final validation = scheduleValidationError(scheduledAt);
    if (validation != null) return validation;
    final token = await _preferencesService.getFacebookPageToken() ?? '';
    if (token.isEmpty) return 'Connect your Page first.';
    try {
      await _publisher.reschedule(
        postId: postId,
        token: token,
        scheduledAt: scheduledAt,
      );
      try {
        if (getIt.isRegistered<FacebookHistoryService>()) {
          final history = getIt<FacebookHistoryService>();
          for (final record in history.records) {
            if (record.postId == postId) {
              await history.update(record.copyWith(scheduledAt: scheduledAt));
            }
          }
        }
      } catch (_) {}
      return null;
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) {
        ref.read(facebookViewModelProvider.notifier).markExpired();
      }
      return e.message;
    } catch (_) {
      return 'Could not reschedule the post.';
    }
  }

  /// Best-effort reconciliation with `/{page}/scheduled_posts`: any local
  /// scheduled record whose time has passed and is no longer scheduled on
  /// Graph is promoted to published. Fetch failures leave records untouched.
  Future<void> reconcileScheduled() async {
    final conn = ref.read(facebookViewModelProvider);
    if (!conn.isConnected) return;
    final token = await _preferencesService.getFacebookPageToken() ?? '';
    if (token.isEmpty) return;
    if (!getIt.isRegistered<FacebookHistoryService>()) return;
    final history = getIt<FacebookHistoryService>();
    final scheduled = history.records.where((r) => r.isScheduled).toList();
    if (scheduled.isEmpty) return;
    List<FacebookScheduledPost> remote;
    try {
      remote = await _publisher.listScheduled(
        pageId: conn.pageId,
        token: token,
      );
    } catch (_) {
      return;
    }
    final remoteIds = remote.map((p) => p.id).toSet();
    final now = DateTime.now();
    for (final record in scheduled) {
      final due = record.scheduledAt;
      if (due == null || due.isAfter(now)) continue;
      if (remoteIds.contains(record.postId)) continue;
      await history.update(
        record.copyWith(
          status: FacebookPostStatus.published,
          permalink: FacebookPublishResult.permalinkFor(record.postId),
          scheduledAt: null,
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
