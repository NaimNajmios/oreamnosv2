import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/services/facebook_draft_store.dart';
import '../../../../data/services/facebook_diagnostics.dart';
import '../../../../data/services/facebook_expiry_signal.dart';
import '../../../../data/services/facebook_page_service.dart';
import '../../../../data/services/facebook_image_cropper.dart';
import '../../../../data/services/facebook_storage_service.dart';
import '../../../../data/services/facebook_publisher_service.dart';
import '../../../../data/services/facebook_history_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/facebook_api_exception.dart';
import '../../../../data/services/facebook_story_composer.dart';
import '../../../../data/services/facebook_workflow_store.dart';
import '../../../../domain/models/facebook_publish_workflow.dart';
import '../../../../domain/models/facebook_post_record.dart';
import '../../../../domain/services/facebook_story_title.dart';
import '../../../../domain/services/facebook_text_formatter.dart';
import 'facebook_state.dart';

/// Result of a gallery/camera attach attempt. Callers should surface
/// [MediaAttachFailed]; [MediaAttachCancelled] is a normal user abort.
sealed class MediaAttachResult {
  const MediaAttachResult();
}

class MediaAttachAdded extends MediaAttachResult {
  const MediaAttachAdded(this.count);

  final int count;
}

class MediaAttachCancelled extends MediaAttachResult {
  const MediaAttachCancelled();
}

class MediaAttachFailed extends MediaAttachResult {
  const MediaAttachFailed(this.message);

  final String message;
}

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
    FacebookExpirySignal.onExpired = _markExpiredFromSignal;
    ref.onDispose(() {
      if (identical(FacebookExpirySignal.onExpired, _markExpiredFromSignal)) {
        FacebookExpirySignal.onExpired = null;
      }
    });
    // Defer until the connection provider has finished building: the
    // maintenance path reads the draft provider, and the draft provider reads
    // this connection provider.
    Future.microtask(_runStartupMaintenance);
    // Expired status starts as connected: only a failed publish (190)
    // marks it expired, and the next publish should try again first.
    return FacebookUiState(
      status: activeId.isEmpty
          ? FacebookConnectionStatus.notConnected
          : FacebookConnectionStatus.connected,
      pageId: active?.id ?? activeId,
      pageName: active?.name ?? _preferencesService.facebookPageName ?? '',
      pagePictureUrl:
          active?.pictureUrl ?? _preferencesService.facebookPagePicture ?? '',
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
      connectionRevision: state.connectionRevision + 1,
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
      connectionRevision: state.connectionRevision + 1,
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
      final page = await _pageService.verifyPageToken(trimmed);
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

  /// Removes tokens, Page identities, publish history, drafts and local files.
  Future<void> disconnect() async {
    try {
      await getIt<FacebookHistoryService>().clear();
    } catch (_) {}
    try {
      final drafts = getIt<FacebookDraftStore>();
      for (final draft in drafts.loadAll()) {
        await drafts.delete(draft.id);
      }
    } catch (_) {}
    try {
      await getIt<FacebookStorageService>().sweep();
    } catch (_) {}
    await _preferencesService.disconnectFacebook();
    state = FacebookUiState(connectionRevision: state.connectionRevision + 1);
  }

  /// Marks the stored token as expired after a 190 publish failure; the
  /// compose screen then offers Reconnect instead of plain Retry.
  void markExpired() {
    if (state.status == FacebookConnectionStatus.connected) {
      state = state.copyWith(
        status: FacebookConnectionStatus.expired,
        connectionRevision: state.connectionRevision + 1,
      );
    }
  }

  void _markExpiredFromSignal() => markExpired();

  /// Five-minute floor between automatic presence probes. Pulled-to-refresh
  /// and explicit retries bypass it.
  static const Duration _healthCheckInterval = Duration(minutes: 5);
  DateTime? _lastHealthCheck;
  bool _healthCheckInFlight = false;

  /// Cheap `GET /me` pre-flight, run when the Publish tab opens and when the
  /// app resumes. It never blocks editing:
  /// - transport failure sets [FacebookUiState.offline] and keeps the token;
  /// - a 190/permission failure marks the connection expired so Reconnect is
  ///   offered before the user loses a long caption to a failed publish.
  Future<void> checkConnectionHealth({bool force = false}) async {
    if (!state.isConnected || _healthCheckInFlight) return;
    final now = DateTime.now();
    final last = _lastHealthCheck;
    if (!force && last != null && now.difference(last) < _healthCheckInterval) {
      return;
    }
    _healthCheckInFlight = true;
    _lastHealthCheck = now;
    state = state.copyWith(lastHealthCheckAt: now);
    try {
      final token = await _preferencesService.getFacebookPageToken() ?? '';
      if (token.isEmpty) return;
      await _pageService.verifyPageToken(token);
      state = state.copyWith(offline: false, lastHealthErrorKind: null);
    } on FacebookApiException catch (e) {
      FacebookDiagnostics.failure(
        'Connection health check',
        e,
        pageId: state.activePageId,
      );
      state = state.copyWith(lastHealthErrorKind: e.kind.name);
      if (e.kind == FacebookApiErrorKind.network) {
        if (!state.offline) state = state.copyWith(offline: true);
      } else if (e.needsReconnect) {
        markExpired();
      }
    } catch (_) {
      // Unknown failure: leave the connection untouched rather than guess.
      state = state.copyWith(lastHealthErrorKind: 'unexpected');
    } finally {
      _healthCheckInFlight = false;
    }
  }

  /// Non-blocking startup maintenance: storage sweep (daily) and scheduled
  /// reconciliation (15 minutes). Both are throttled and best-effort.
  Future<void> _runStartupMaintenance() async {
    try {
      final now = DateTime.now();
      final lastSweep = _preferencesService.lastFacebookSweep;
      if (lastSweep == null ||
          now.difference(lastSweep) > const Duration(hours: 24)) {
        await getIt<FacebookStorageService>().sweep();
        await _preferencesService.setLastFacebookSweep(now);
      }
      final lastReconcile = _preferencesService.lastFacebookReconcile;
      if (lastReconcile == null ||
          now.difference(lastReconcile) > const Duration(minutes: 15)) {
        await ref.read(facebookDraftProvider.notifier).reconcileScheduled();
        await _preferencesService.setLastFacebookReconcile(now);
      }
    } catch (_) {}
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
  late final FacebookDraftStore _draftStore;
  Timer? _autosaveTimer;
  Timer? _reconcileRetryTimer;
  int _reconcileRetryAttempt = 0;
  bool _reconcileInFlight = false;
  static const Duration _reconcileTtl = Duration(minutes: 2);
  int _saveSequence = 0;
  String? _activeDraftId;
  String _pageId = '';
  String _pageName = '';

  String? get activeDraftId => _activeDraftId;

  @override
  FacebookComposeState build() {
    _publisher = getIt<FacebookPublisherService>();
    _preferencesService = getIt<PreferencesService>();
    _draftStore = getIt<FacebookDraftStore>();
    ref.onDispose(() {
      _autosaveTimer?.cancel();
      _reconcileRetryTimer?.cancel();
    });
    final connection = ref.read(facebookViewModelProvider);
    _pageId = connection.activePageId;
    _pageName = connection.pageName;
    _activeDraftId = _draftStore.activeDraftId;
    unawaited(_draftStore.pruneOrphans());

    final stored = _draftStore.loadActive();
    if (stored != null) {
      _pageId = stored.pageId.isEmpty ? _pageId : stored.pageId;
      _pageName = stored.pageName.isEmpty ? _pageName : stored.pageName;
      return _fromRecord(stored, restored: true);
    }

    // v10/v9 single-draft key: restore synchronously, then migrate into the
    // multi-draft store on the first autosave.
    final legacy = _restoreLegacyDraft();
    if (legacy != null) {
      _activeDraftId ??= _newMediaId();
      return legacy;
    }
    return FacebookComposeState(pageId: _pageId);
  }

  FacebookComposeState _fromRecord(
    FacebookDraftRecord record, {
    required bool restored,
  }) {
    return FacebookComposeState(
      text: record.text,
      media: record.media
          .map(FacebookMediaItem.fromJson)
          .toList(growable: false),
      publishMode: record.mode == FacebookPublishMode.scheduled.name
          ? FacebookPublishMode.scheduled
          : FacebookPublishMode.now,
      scheduledAt: record.scheduledAt,
      restoredFromStorage: restored,
      pageId: record.pageId,
      workflowId: record.workflowId,
      workflowName: record.workflowName,
      publishFeed: record.publishFeed,
      storyEnabled: record.storyEnabled,
      storyTitle: record.storyTitle,
    );
  }

  FacebookComposeState? _restoreLegacyDraft() {
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
        pageId: snapshot.pageId.isEmpty ? _pageId : snapshot.pageId,
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
    String? title,
  }) {
    _autosaveTimer?.cancel();
    final connection = ref.read(facebookViewModelProvider);
    _pageId = connection.activePageId;
    _pageName = connection.pageName;
    if (state.isEmpty && _activeDraftId != null) {
      // Reuse an empty active draft instead of accumulating empty records.
    } else {
      _activeDraftId = _newMediaId();
    }
    final plainText = FacebookTextFormatter.toPlainText(rawMarkdown);
    final workflow = getIt<FacebookWorkflowStore>().defaultForPage(_pageId);
    final storyTitle = FacebookStoryTitle.extract(
      text: plainText,
      headline: title,
    );
    state = FacebookComposeState(
      text: plainText,
      media: [
        if (imagePath != null && imagePath.isNotEmpty)
          FacebookMediaItem(
            id: _newMediaId(),
            path: imagePath,
            aspect: imageAspect ?? FacebookImageAspect.portrait,
          ),
      ],
      pageId: _pageId,
      draftTitle: title?.trim() ?? '',
      workflowId: workflow.id,
      workflowName: workflow.name,
      publishFeed: workflow.publishFeed,
      storyEnabled: workflow.storyEnabled,
      storyTitle: storyTitle,
    );
    _scheduleAutosave();
  }

  /// Starts an empty draft (drafts screen FAB / "new post").
  void startEmptyDraft() {
    _autosaveTimer?.cancel();
    final connection = ref.read(facebookViewModelProvider);
    _pageId = connection.activePageId;
    _pageName = connection.pageName;
    _activeDraftId = null;
    final workflow = getIt<FacebookWorkflowStore>().defaultForPage(_pageId);
    state = FacebookComposeState(
      pageId: _pageId,
      workflowId: workflow.id,
      workflowName: workflow.name,
      publishFeed: workflow.publishFeed,
      storyEnabled: workflow.storyEnabled,
    );
  }

  /// Loads an existing draft, saving the current one first when different.
  Future<bool> openDraft(String id) async {
    if (id == _activeDraftId) return true;
    if (!state.isEmpty && _activeDraftId != null) {
      await _saveNow();
    }
    FacebookDraftRecord? record;
    for (final item in _draftStore.loadAll()) {
      if (item.id == id) {
        record = item;
        break;
      }
    }
    if (record == null) return false;
    _autosaveTimer?.cancel();
    _activeDraftId = record.id;
    _pageId = record.pageId.isEmpty ? _pageId : record.pageId;
    _pageName = record.pageName.isEmpty ? _pageName : record.pageName;
    state = _fromRecord(record, restored: false);
    await _draftStore.setActive(record.id);
    return true;
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

  /// Applies a workflow preset to this draft (does not change the default).
  void applyWorkflow(FacebookPublishWorkflow workflow) {
    final title = state.storyTitle.trim().isNotEmpty
        ? state.storyTitle
        : FacebookStoryTitle.extract(
            text: state.text,
            headline: state.draftTitle,
          );
    state = state.copyWith(
      workflowId: workflow.id,
      workflowName: workflow.name,
      publishFeed: workflow.publishFeed,
      storyEnabled: workflow.storyEnabled,
      storyTitle:
          workflow.storyTitleSource == FacebookStoryTitleSource.custom &&
              workflow.customTitle.trim().isNotEmpty
          ? workflow.customTitle.trim()
          : title,
    );
    _scheduleAutosave();
  }

  void setStoryEnabled(bool value) {
    if (state.storyEnabled == value) return;
    final title = state.storyTitle.trim().isNotEmpty
        ? state.storyTitle
        : FacebookStoryTitle.extract(
            text: state.text,
            headline: state.draftTitle,
          );
    state = state.copyWith(
      storyEnabled: value,
      storyTitle: title,
      workflowId: '',
      workflowName: '',
    );
    _scheduleAutosave();
  }

  void setPublishFeed(bool value) {
    if (state.publishFeed == value) return;
    state = state.copyWith(
      publishFeed: value,
      workflowId: '',
      workflowName: '',
    );
    _scheduleAutosave();
  }

  void setStoryTitle(String value) {
    state = state.copyWith(storyTitle: value);
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
    final oldId = _activeDraftId;
    _activeDraftId = null;
    state = FacebookComposeState(pageId: _pageId);
    unawaited(_preferencesService.clearFacebookDraft());
    if (oldId != null) unawaited(_draftStore.delete(oldId));
  }

  /// "Publish another" — keeps the connection, resets text + attachment.
  void resetForAnotherPost() {
    clearDraft();
  }

  /// Explicit Save draft action. Also used before opening another draft.
  Future<void> saveDraftNow() => _saveNow();

  /// Persists the current draft into the multi-draft store, copying photos
  /// into app documents so temp cleanup cannot lose them.
  Future<void> _saveNow() async {
    if (state.isFinished) return;
    if (state.isEmpty) {
      final oldId = _activeDraftId;
      _activeDraftId = null;
      await _preferencesService.clearFacebookDraft();
      if (oldId != null) await _draftStore.delete(oldId);
      if (state.draftSaveState != FacebookDraftSaveState.idle) {
        state = state.copyWith(draftSaveState: FacebookDraftSaveState.idle);
      }
      return;
    }
    final sequence = ++_saveSequence;
    state = state.copyWith(draftSaveState: FacebookDraftSaveState.saving);
    try {
      final id = _activeDraftId ??= _newMediaId();
      final raw = state.media.map((m) => m.toJson()).toList();
      final media = await _draftStore.importMedia(id, raw);
      final items = media
          .map(FacebookMediaItem.fromJson)
          .toList(growable: false);
      if (!_sameMediaPaths(state.media, items)) {
        state = state.copyWith(media: items);
      }
      final pageId = state.pageId.isEmpty ? _pageId : state.pageId;
      await _draftStore.save(
        FacebookDraftRecord(
          id: id,
          text: state.text,
          media: media,
          pageId: pageId,
          pageName: _pageName,
          mode: state.publishMode.name,
          scheduledAt: state.scheduledAt,
          updatedAt: DateTime.now(),
          workflowId: state.workflowId,
          workflowName: state.workflowName,
          publishFeed: state.publishFeed,
          storyEnabled: state.storyEnabled,
          storyTitle: state.storyTitle,
        ),
      );
      // The legacy key is migrated into the store after the first save.
      await _preferencesService.clearFacebookDraft();
      if (sequence == _saveSequence) {
        state = state.copyWith(
          draftSaveState: FacebookDraftSaveState.saved,
          lastDraftSavedAt: DateTime.now(),
        );
      }
    } catch (_) {
      if (sequence == _saveSequence) {
        state = state.copyWith(draftSaveState: FacebookDraftSaveState.failed);
      }
    }
  }

  static bool _sameMediaPaths(
    List<FacebookMediaItem> a,
    List<FacebookMediaItem> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path) return false;
    }
    return true;
  }

  /// Drops the active draft after a successful publish.
  Future<void> _discardActiveDraft() async {
    _autosaveTimer?.cancel();
    final id = _activeDraftId;
    _activeDraftId = null;
    await _preferencesService.clearFacebookDraft();
    if (id != null) await _draftStore.delete(id);
  }

  /// Deletes another draft and clears the editor when it is the active one.
  Future<void> deleteDraft(String id) async {
    await _draftStore.delete(id);
    if (_activeDraftId != id) return;
    _autosaveTimer?.cancel();
    _activeDraftId = null;
    state = FacebookComposeState(pageId: _pageId);
  }

  /// Retargets the current draft to another Page (mismatch dialog choice).
  void retargetDraft(String pageId, {String? pageName}) {
    if (pageId.isEmpty) return;
    _pageId = pageId;
    if (pageName != null && pageName.isNotEmpty) _pageName = pageName;
    state = state.copyWith(pageId: pageId);
    if (!state.isEmpty) _scheduleAutosave();
  }

  /// Duplicates the current draft for another Page and switches to the copy.
  Future<void> duplicateDraftForPage(String pageId, {String? pageName}) async {
    if (pageId.isEmpty) return;
    await _saveNow();
    final oldId = _activeDraftId;
    if (oldId == null) {
      retargetDraft(pageId, pageName: pageName);
      return;
    }
    final newId = await _draftStore.duplicate(oldId);
    if (newId == null) {
      retargetDraft(pageId, pageName: pageName);
      return;
    }
    FacebookDraftRecord? copy;
    for (final item in _draftStore.loadAll()) {
      if (item.id == newId) {
        copy = item;
        break;
      }
    }
    if (copy == null) return;
    _activeDraftId = newId;
    _pageId = pageId;
    if (pageName != null && pageName.isNotEmpty) _pageName = pageName;
    state = state.copyWith(pageId: pageId);
    await _draftStore.save(
      copy.copyWith(
        pageId: pageId,
        pageName: _pageName,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Saves the current draft to the store after a short idle period.
  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    if (!state.isEmpty && !state.isFinished) {
      state = state.copyWith(draftSaveState: FacebookDraftSaveState.pending);
    }
    _autosaveTimer = Timer(_autosaveDebounce, () {
      unawaited(_saveNow());
    });
  }

  /// Gallery pick for one or more photos (cap 10).
  Future<MediaAttachResult> attachImages(ImageSource source) async {
    if (!state.canAddMoreMedia) {
      return const MediaAttachFailed(
        'You already attached the maximum photos.',
      );
    }
    final slots = FacebookLimits.maxPhotos - state.media.length;
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2048,
        imageQuality: 85,
        limit: slots,
      );
      if (files.isEmpty) return const MediaAttachCancelled();
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
      if (added.isEmpty) return const MediaAttachCancelled();
      state = state.copyWith(
        media: [...state.media, ...added],
        restoredFromStorage: false,
      );
      _scheduleAutosave();
      return MediaAttachAdded(added.length);
    } catch (_) {
      return const MediaAttachFailed(
        'Could not add photos. Check photo permissions and try again.',
      );
    }
  }

  /// Camera pick — replaces the current photos with a single new capture.
  Future<MediaAttachResult> attachImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (picked == null) return const MediaAttachCancelled();
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
      return const MediaAttachAdded(1);
    } catch (_) {
      return const MediaAttachFailed(
        'Could not open the camera. Check camera permissions and try again.',
      );
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
    clearMedia();
  }

  /// Marks the restore notice as shown so it does not reappear on every
  /// composer entry.
  void acknowledgeRestore() {
    if (state.restoredFromStorage) {
      state = state.copyWith(restoredFromStorage: false);
    }
  }

  /// Removes every attached photo.
  void clearMedia() {
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
    final storyOnly = state.storyEnabled && !state.publishFeed;
    if (state.isPublishing ||
        state.isPreparing ||
        state.isFinished ||
        (!state.hasText && !storyOnly)) {
      return;
    }
    if (!state.publishFeed && !state.storyEnabled) {
      _fail('Choose Page post, Story, or both.');
      return;
    }
    if (state.publishMode == FacebookPublishMode.scheduled &&
        state.storyEnabled) {
      _fail(
        "Facebook Stories can't be scheduled. Post now or remove the Story.",
        kind: FacebookApiErrorKind.storySchedulingUnsupported,
      );
      return;
    }

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

    final storyTitle = state.storyTitle.trim().isNotEmpty
        ? state.storyTitle.trim()
        : FacebookStoryTitle.extract(
            text: state.text,
            headline: state.draftTitle,
          );
    if (state.storyEnabled && storyTitle.isEmpty) {
      _fail('Add a short title for the Story.');
      return;
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
      phase: mediaItems.isEmpty
          ? FacebookComposePhase.publishing
          : FacebookComposePhase.compressing,
      uploadProgress: mediaItems.isEmpty ? null : 0.0,
      error: null,
      storyError: null,
      storyResult: null,
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
      FacebookPublishResult? feedResult;
      FacebookStoryResult? storyResult;
      String? storyError;
      String? storyPath;

      if (state.publishFeed) {
        if (mediaItems.isEmpty) {
          feedResult = await _publisher.publishText(
            pageId: pageId,
            token: token,
            message: state.text,
            scheduledAt: scheduled ? scheduledAt : null,
          );
        } else if (mediaItems.length == 1) {
          final media = mediaItems.single;
          final uploadPath = await _cropForUpload(media);
          state = state.copyWith(phase: FacebookComposePhase.publishing);
          feedResult = await _publisher.publishPhoto(
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
          feedResult = await _publishMultiple(
            pageId: pageId,
            token: token,
            media: mediaItems,
            scheduledAt: scheduled ? scheduledAt : null,
          );
        }
      }

      if (state.storyEnabled) {
        String outputDir;
        try {
          outputDir = (await getTemporaryDirectory()).path;
        } catch (_) {
          outputDir = Directory.systemTemp.path;
        }
        storyPath = await getIt<FacebookStoryComposer>().compose(
          sourceImagePath: mediaItems.isEmpty ? null : mediaItems.first.path,
          title: storyTitle,
          outputDir: outputDir,
        );
        String? storyPhotoId;
        try {
          storyPhotoId = await _publisher.uploadUnpublishedPhoto(
            pageId: pageId,
            token: token,
            filePath: storyPath,
            altText: storyTitle,
          );
          storyResult = await _publisher.publishPhotoStory(
            pageId: pageId,
            token: token,
            photoId: storyPhotoId,
          );
        } on FacebookApiException catch (e) {
          storyError = e.message;
          if (e.needsReconnect) {
            ref.read(facebookViewModelProvider.notifier).markExpired();
          }
          if (storyPhotoId != null) {
            await _publisher.deletePhoto(photoId: storyPhotoId, token: token);
          }
        }
      }

      final result =
          feedResult ??
          (storyResult != null
              ? FacebookPublishResult(
                  id: storyResult.postId,
                  postId: storyResult.postId,
                  permalink: '',
                  isPhoto: true,
                  isScheduled: false,
                  scheduledAt: null,
                )
              : null);
      if (result == null) {
        state = state.copyWith(
          phase: FacebookComposePhase.publishError,
          uploadProgress: null,
          storyError: storyError,
          error: FacebookApiException(
            kind: FacebookApiErrorKind.storyUnavailable,
            message: storyError ?? 'Publishing failed. Try again.',
          ),
        );
        return;
      }

      state = state.copyWith(
        phase: storyError != null
            ? FacebookComposePhase.partialSuccess
            : scheduled
            ? FacebookComposePhase.scheduled
            : FacebookComposePhase.published,
        uploadProgress: null,
        result: result,
        storyResult: storyResult,
        storyError: storyError,
        storyImagePath: storyPath,
      );
      _autosaveTimer?.cancel();
      unawaited(_discardActiveDraft());
      FacebookDiagnostics.event(
        scheduled ? 'Scheduled post' : 'Published post',
        pageId: pageId,
      );
      // Persist for the Published / Scheduled history.
      try {
        if (getIt.isRegistered<FacebookHistoryService>()) {
          await getIt<FacebookHistoryService>().recordPublish(
            postId: result.postId,
            message: state.text,
            permalink: result.permalink,
            hasImage: result.isPhoto || state.hasImage,
            sourceImagePaths: [...state.media.map((m) => m.path), ?storyPath],
            status: scheduled
                ? FacebookPostStatus.scheduled
                : FacebookPostStatus.published,
            scheduledAt: scheduled ? scheduledAt : null,
            pageId: pageId,
            pageName: conn.pageName,
            mediaMetadata: state.media.map((m) => m.toJson()).toList(),
            storyPostId: storyResult?.postId ?? '',
            storyStatus: storyResult != null
                ? FacebookStoryStatus.published
                : storyError != null
                ? FacebookStoryStatus.failed
                : FacebookStoryStatus.none,
            storyTitle: state.storyEnabled ? storyTitle : '',
            storyImagePath: storyPath ?? '',
            workflowId: state.workflowId,
            workflowName: state.workflowName,
            isStoryOnly: !state.publishFeed,
          );
        }
      } catch (_) {}
    } on FacebookApiException catch (e) {
      FacebookDiagnostics.failure('Publish', e, pageId: pageId);
      if (e.needsReconnect) {
        ref.read(facebookViewModelProvider.notifier).markExpired();
      }
      final uncertain =
          e.kind == FacebookApiErrorKind.network ||
          e.kind == FacebookApiErrorKind.unexpectedResponse;
      state = state.copyWith(
        phase: uncertain
            ? FacebookComposePhase.publishUncertain
            : FacebookComposePhase.publishError,
        uploadProgress: null,
        error: e,
      );
    } catch (_) {
      _fail('Publishing failed unexpectedly. Try again.');
    }
  }

  /// Uploads every photo unpublished, then creates one feed post. Any
  /// failure aborts before the feed post and deletes uploaded photos.
  ///
  /// Progress is byte-weighted across the prepared files; a failure names the
  /// photo index so the user knows which attachment to fix.
  Future<FacebookPublishResult> _publishMultiple({
    required String pageId,
    required String token,
    required List<FacebookMediaItem> media,
    DateTime? scheduledAt,
  }) async {
    final photoIds = <String>[];
    var currentIndex = 0;
    try {
      state = state.copyWith(
        phase: FacebookComposePhase.compressing,
        uploadProgress: 0.0,
      );
      final uploadPaths = <String>[];
      for (final item in media) {
        uploadPaths.add(await _cropForUpload(item));
      }
      final sizes = <int>[];
      for (final path in uploadPaths) {
        final size = File(path).lengthSync();
        sizes.add(size > 0 ? size : 1);
      }
      final totalBytes = sizes.fold<int>(0, (sum, size) => sum + size);
      var uploadedBytes = 0;
      state = state.copyWith(phase: FacebookComposePhase.publishing);

      for (var i = 0; i < media.length; i++) {
        currentIndex = i;
        final item = media[i];
        final id = await _publisher.uploadUnpublishedPhoto(
          pageId: pageId,
          token: token,
          filePath: uploadPaths[i],
          altText: item.altText,
          onSendProgress: (sent, total) {
            if (!state.isPublishing || total <= 0 || totalBytes <= 0) return;
            final currentBytes = (sent / total) * sizes[i];
            final overall = ((uploadedBytes + currentBytes) / totalBytes).clamp(
              0.0,
              1.0,
            );
            state = state.copyWith(uploadProgress: overall);
          },
        );
        photoIds.add(id);
        uploadedBytes += sizes[i];
      }
      return await _publisher.publishMultiPhoto(
        pageId: pageId,
        token: token,
        photoIds: photoIds,
        message: state.text,
        scheduledAt: scheduledAt,
      );
    } on FacebookApiException catch (e) {
      for (final id in photoIds) {
        await _publisher.deletePhoto(photoId: id, token: token);
      }
      throw FacebookApiException(
        kind: FacebookApiErrorKind.mediaUploadFailed,
        message:
            'Photo ${currentIndex + 1} of ${media.length} failed: ${e.message}',
        code: e.code,
        subcode: e.subcode,
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

  /// Retries reconciliation when the last attempt is older than [maxAge].
  /// Called from the app-resume hook to recover from a backoff that expired
  /// while the app was backgrounded.
  Future<void> reconcileIfStale({
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    final conn = ref.read(facebookViewModelProvider);
    if (!conn.isConnected) return;
    final last = _preferencesService.lastFacebookReconcile;
    if (last != null && DateTime.now().difference(last) < maxAge) return;
    await reconcileScheduled();
    if (!state.scheduledSyncFailed) {
      await _preferencesService.setLastFacebookReconcile(DateTime.now());
    }
  }

  /// Best-effort reconciliation with `/{page}/scheduled_posts`: any local
  /// scheduled record whose time has passed and is no longer scheduled on
  /// Graph is promoted to published. Fetch failures leave records untouched.
  /// Non-forced calls are throttled for [_reconcileTtl] because the hub
  /// remounts on every tab switch.
  Future<void> reconcileScheduled({bool force = false}) async {
    if (_reconcileInFlight) return;
    if (!force) {
      final last = _preferencesService.lastFacebookReconcile;
      if (last != null && DateTime.now().difference(last) < _reconcileTtl) {
        return;
      }
    }
    _reconcileInFlight = true;
    try {
      await _reconcileScheduledBody(force: force);
    } finally {
      _reconcileInFlight = false;
    }
  }

  Future<void> _reconcileScheduledBody({required bool force}) async {
    if (force) _cancelReconcileRetry();
    final conn = ref.read(facebookViewModelProvider);
    if (!conn.isConnected) return;
    final token = await _preferencesService.getFacebookPageToken() ?? '';
    if (token.isEmpty) return;
    if (!getIt.isRegistered<FacebookHistoryService>()) return;
    final history = getIt<FacebookHistoryService>();
    final scheduled = history.records.where((r) => r.isScheduled).toList();
    if (scheduled.isEmpty) {
      _cancelReconcileRetry();
      await _preferencesService.setLastFacebookReconcile(DateTime.now());
      if (state.scheduledSyncFailed) {
        state = state.copyWith(scheduledSyncFailed: false);
      }
      return;
    }
    List<FacebookScheduledPost> remote;
    try {
      remote = await _publisher.listScheduled(
        pageId: conn.pageId,
        token: token,
      );
    } catch (e) {
      FacebookDiagnostics.failure(
        'Scheduled post sync',
        e,
        pageId: conn.pageId,
      );
      if (!state.scheduledSyncFailed) {
        state = state.copyWith(scheduledSyncFailed: true);
      }
      _scheduleReconcileRetry();
      return;
    }
    _cancelReconcileRetry();
    await _preferencesService.setLastFacebookReconcile(DateTime.now());
    if (state.scheduledSyncFailed) {
      state = state.copyWith(scheduledSyncFailed: false);
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

  /// Retries a failed reconciliation without hammering Graph: 2s, 8s, 30s,
  /// then give up until the next app/hub refresh. The banner clears on the
  /// first success.
  static const List<Duration> _reconcileBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 8),
    Duration(seconds: 30),
  ];

  void _cancelReconcileRetry() {
    _reconcileRetryTimer?.cancel();
    _reconcileRetryTimer = null;
    _reconcileRetryAttempt = 0;
  }

  void _scheduleReconcileRetry() {
    if (_reconcileRetryTimer != null) return;
    if (_reconcileRetryAttempt >= _reconcileBackoff.length) return;
    final delay = _reconcileBackoff[_reconcileRetryAttempt];
    _reconcileRetryAttempt++;
    _reconcileRetryTimer = Timer(delay, () {
      _reconcileRetryTimer = null;
      unawaited(reconcileScheduled());
    });
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
