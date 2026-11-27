import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/log_service.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  static const MethodChannel _shareIntentChannel = MethodChannel(
    'oreamnos_share_intent',
  );

  /// SharedPreferences key storing the dedup key of the last handled
  /// initial share. Persists across processes so a cold start can tell a
  /// *stale replay* (Android cached process replays the previous session's
  /// `initialMedia`) apart from a *fresh share* (≠ fingerprint → handled).
  static const String _fingerprintPrefKey = 'share_initial_fingerprint';
  static const String _fingerprintAtPrefKey = 'share_initial_fingerprint_at';

  /// A cached-process replay lands shortly after relaunch. A deliberate
  /// re-share of the *same* URL later is a fresh share and must not be
  /// mistaken for one, so the fingerprint guard is time-bounded.
  static const Duration _replayGuardWindow = Duration(seconds: 30);

  StreamSubscription? _intentDataStreamSubscription;
  DateTime? _lastHandledTime;
  String? _lastHandledContent;

  /// Dedup key of the last handled share. Loaded from prefs before the
  /// initial delivery is judged; persisted after *every* handled share so
  /// the stream and initial paths share one fingerprint.
  String? _initialFingerprint;
  DateTime? _initialFingerprintAt;

  /// Keys delivered on the live stream in this process. A later initial
  /// delivery of the same key is a fresh share (or a bounce), never a
  /// cached-process replay of the previous session.
  final Set<String> _seenStreamKeys = <String>{};

  /// Android keeps a cached process after swipe-away; the native plugin's
  /// `initialMedia`/`latestMedia` survive it. This guards each process from
  /// consuming the initial intent more than once.
  bool _initialMediaConsumed = false;

  /// Callback fired when new text or URL is shared to the app
  Function(String)? onSharedTextReceived;

  void _log(String message, [Object? error, StackTrace? stackTrace]) {
    try {
      if (getIt.isRegistered<LogService>()) {
        final logService = getIt<LogService>();
        if (error != null) {
          logService.error(
            'ShareIntent: $message',
            error: error,
            stackTrace: stackTrace,
          );
        } else {
          logService.info('ShareIntent: $message');
        }
      } else {
        debugPrint('ShareIntent: $message${error != null ? ' $error' : ''}');
      }
    } catch (_) {
      debugPrint('ShareIntent: $message${error != null ? ' $error' : ''}');
    }
  }

  Future<void> _resetNativePlugin() async {
    try {
      await ReceiveSharingIntent.instance.reset();
    } catch (e, st) {
      _log('plugin reset failed', e, st);
    }
    try {
      await _shareIntentChannel.invokeMethod<void>('clearIntent');
    } on MissingPluginException {
      // Expected in unit/widget tests or non-Android platforms.
    } catch (e, st) {
      _log('native intent clear failed', e, st);
    }
  }

  void initialize() {
    // NOTE: never call `reset()` BEFORE `getInitialMedia()` — the plugin's
    // reset clears the stored initial intent, so purging first would kill
    // the *fresh* cold-start share (the "share lands on a blank Generate
    // screen" regression). Stale-replay protection is handled by the
    // fingerprint check in [handleSharedMedia] instead.

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            handleSharedMedia(value);
            // Clear the stream intent cache so warm resumptions don't replay stale data
            unawaited(_resetNativePlugin());
          },
          onError: (err, st) {
            _log('getMediaStream error', err, st);
          },
        );

    // For sharing or opening urls/text coming from outside the app while the app is closed
    if (!_initialMediaConsumed) {
      _initialMediaConsumed = true;
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> value) async {
            // Load the persisted fingerprint BEFORE judging this delivery —
            // a stale replay (same content as the last handled share) is
            // dropped here, a fresh share (≠ fingerprint) is handled.
            _initialFingerprint ??= await _loadFingerprint();
            handleSharedMedia(value, isInitial: true);
            // Tell the library and MainActivity that we are done processing the initial intent
            await _resetNativePlugin();
          })
          .catchError((err, st) {
            _log('getInitialMedia error', err, st);
          });
    }
  }

  Future<String?> _loadFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _initialFingerprintAt ??= _readTimestamp(
        prefs.getString(_fingerprintAtPrefKey),
      );
      return prefs.getString(_fingerprintPrefKey);
    } catch (e, st) {
      _log('fingerprint load failed', e, st);
      return null;
    }
  }

  DateTime? _readTimestamp(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  void _persistFingerprint(String dedupKey, DateTime at) {
    try {
      SharedPreferences.getInstance()
          .then((prefs) async {
            await prefs.setString(_fingerprintPrefKey, dedupKey);
            await prefs.setString(_fingerprintAtPrefKey, at.toIso8601String());
          })
          .catchError((Object e, StackTrace st) {
            _log('fingerprint save failed', e, st);
            // Future<void> catchError contract: must return a default value.
          });
    } catch (e, st) {
      _log('fingerprint save failed', e, st);
    }
  }

  /// Normalizes shared content so dedup compares the *logical* share, not
  /// byte-identical strings. X shares the same tweet in several forms
  /// (`?s=20&t=…`, `t.co`, clients re-encoding whitespace); tracking params
  /// must not make a re-share look like new content — and vice versa, they
  /// must not make the *new* share look stale.
  static String normalizeDedupKey(String content) {
    var key = content.trim();
    final urlMatch = RegExp(
      r'https?://\S+',
      caseSensitive: false,
    ).firstMatch(key);
    if (urlMatch != null) {
      var url = urlMatch.group(0)!;
      // Strip tracking query entirely — tweet/status path identifies content.
      final queryIndex = url.indexOf('?');
      if (queryIndex > 0) url = url.substring(0, queryIndex);
      while (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      url = url.toLowerCase();
      return url;
    }
    // Plain text: collapse whitespace so client-side re-encoding matches.
    return key.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  @visibleForTesting
  void resetDeduplicationForTesting() {
    _lastHandledTime = null;
    _lastHandledContent = null;
    _initialMediaConsumed = false;
    _initialFingerprint = null;
    _initialFingerprintAt = null;
    _seenStreamKeys.clear();
  }

  /// Clears only the short-window dedup markers, keeping the initial-share
  /// fingerprint guard intact — lets tests prove that a same-content
  /// delivery beyond the 1500ms window (the stale-replay scenario) is
  /// suppressed on the initial path.
  @visibleForTesting
  void expireTransientDedupForTesting() {
    _lastHandledTime = null;
    _lastHandledContent = null;
  }

  /// Models a fingerprint persisted long ago (outside [_replayGuardWindow])
  /// for tests that replay a fresh share of the same content.
  @visibleForTesting
  void expireReplayGuardForTesting() {
    _initialFingerprintAt = DateTime.now().subtract(_replayGuardWindow * 2);
  }

  @visibleForTesting
  String? get initialFingerprintForTesting => _initialFingerprint;

  /// Loads the persisted fingerprint exactly as the initial path inside
  /// [initialize] does, right before judging the cold-start delivery.
  /// Test hook for simulating a process restart (fingerprint survives in
  /// prefs, in-memory key is empty).
  @visibleForTesting
  Future<void> loadInitialFingerprintForTesting() async {
    _initialFingerprint ??= await _loadFingerprint();
  }

  @visibleForTesting
  void handleSharedMedia(
    List<SharedMediaFile> files, {
    bool isInitial = false,
  }) {
    if (files.isEmpty) {
      _log('received empty media list (share may have been dropped)');
      return;
    }

    // Some apps attach a preview image (ACTION_SEND_MULTIPLE) ahead of the
    // shared text/URL. Inspecting only `files.first` silently dropped those
    // shares — the app opened but nothing was pasted or generated.
    SharedMediaFile? textFile;
    for (final candidate in files) {
      if (candidate.type == SharedMediaType.text ||
          candidate.type == SharedMediaType.url) {
        textFile = candidate;
        break;
      }
    }
    if (textFile == null) {
      _log('no text/url item among ${files.length} shared media');
      return;
    }

    final content = textFile.path.trim();
    if (content.isEmpty) return;

    final dedupKey = normalizeDedupKey(content);
    final now = DateTime.now();

    // Debounce duplicate events within 1500ms (common on Android resume/stream rebroadcasts)
    if (_lastHandledContent == dedupKey &&
        _lastHandledTime != null &&
        now.difference(_lastHandledTime!) <
            const Duration(milliseconds: 1500)) {
      _log('ignoring duplicate share intent event: $dedupKey');
      return;
    }

    // If the live stream already delivered this key in the current process,
    // a later `getInitialMedia()` resolution for the same key is a startup
    // duplicate (e.g., delayed by SharedPreferences load), not a new share.
    if (isInitial && _seenStreamKeys.contains(dedupKey)) {
      _log('suppressing initial delivery already handled on stream: $dedupKey');
      return;
    }
    if (!isInitial) _seenStreamKeys.add(dedupKey);

    // Stale-replay guard (initial path only): Android's cached process can
    // replay the previous session's share on relaunch. The guard is bounded
    // in time so re-sharing the same URL later still works.
    final replayAge = _initialFingerprintAt == null
        ? null
        : now.difference(_initialFingerprintAt!);
    if (isInitial &&
        _initialFingerprint == dedupKey &&
        replayAge != null &&
        replayAge >= Duration.zero &&
        replayAge < _replayGuardWindow) {
      _log('suppressing stale initial replay: $dedupKey');
      return;
    }

    _lastHandledTime = now;
    _lastHandledContent = dedupKey;
    // Keep both paths on one fingerprint: a stream delivery followed by a
    // late initial delivery of the same content must not be judged stale.
    _initialFingerprint = dedupKey;
    _initialFingerprintAt = now;
    _persistFingerprint(dedupKey, now);

    final callback = onSharedTextReceived;
    if (callback != null) {
      callback(content);
    } else {
      _log('share received before callback was attached: $dedupKey');
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
