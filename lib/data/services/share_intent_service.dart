import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/log_service.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  /// SharedPreferences key storing the dedup key of the last handled
  /// initial share. Persists across processes so a cold start can tell a
  /// *stale replay* (Android cached process replays the previous session's
  /// `initialMedia`) apart from a *fresh share* (≠ fingerprint → handled).
  static const String _fingerprintPrefKey = 'share_initial_fingerprint';

  StreamSubscription? _intentDataStreamSubscription;
  DateTime? _lastHandledTime;
  String? _lastHandledContent;

  /// Dedup key of the last handled share. Loaded from prefs before the
  /// initial delivery is judged; persisted after each initial share.
  String? _initialFingerprint;

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
            try {
              ReceiveSharingIntent.instance.reset();
            } catch (e, st) {
              _log('stream reset failed', e, st);
            }
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
            // Tell the library that we are done processing the initial intent
            try {
              ReceiveSharingIntent.instance.reset();
            } catch (e, st) {
              _log('initial reset failed', e, st);
            }
          })
          .catchError((err, st) {
            _log('getInitialMedia error', err, st);
          });
    }
  }

  Future<String?> _loadFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fingerprintPrefKey);
    } catch (e, st) {
      _log('fingerprint load failed', e, st);
      return null;
    }
  }

  void _persistFingerprint(String dedupKey) {
    try {
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setString(_fingerprintPrefKey, dedupKey))
          .catchError((Object e, StackTrace st) {
            _log('fingerprint save failed', e, st);
            // Future<bool> catchError contract: must return a default value.
            return false;
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
  @visibleForTesting
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

    final file = files.first;

    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      final content = file.path.trim();
      if (content.isEmpty) return;

      final dedupKey = normalizeDedupKey(content);

      // Debounce duplicate events within 1500ms (common on Android resume/stream rebroadcasts)
      final now = DateTime.now();
      if (_lastHandledContent == dedupKey &&
          _lastHandledTime != null &&
          now.difference(_lastHandledTime!) <
              const Duration(milliseconds: 1500)) {
        _log('ignoring duplicate share intent event: $dedupKey');
        return;
      }

      // Stale-replay guard (initial path only): Android's cached process
      // replays the previous session's share on relaunch. A delivery whose
      // logical key matches the last handled share is a replay, not a fresh
      // share — drop it instead of re-generating the same content.
      if (isInitial && _initialFingerprint == dedupKey) {
        _log('suppressing stale initial replay: $dedupKey');
        return;
      }

      _lastHandledTime = now;
      _lastHandledContent = dedupKey;
      if (isInitial) {
        _initialFingerprint = dedupKey;
        _persistFingerprint(dedupKey);
      }

      final callback = onSharedTextReceived;
      if (callback != null) {
        callback(content);
      } else {
        _log('share received before callback was attached: $dedupKey');
      }
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
