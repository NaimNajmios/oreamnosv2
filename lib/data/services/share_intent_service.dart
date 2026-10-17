import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/log_service.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  StreamSubscription? _intentDataStreamSubscription;
  DateTime? _lastHandledTime;
  String? _lastHandledContent;

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
          logService.error('ShareIntent: $message', error, stackTrace);
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
    // Purge stale native cache FIRST. Android's cached process keeps
    // `latestMedia` from the previous session alive; without this purge a
    // re-subscribe below can replay the *previous* share instead of waiting
    // for the new one ("treated as the last entry" bug).
    try {
      ReceiveSharingIntent.instance.reset();
    } catch (e, st) {
      _log('pre-init reset failed', e, st);
    }

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
          .then((List<SharedMediaFile> value) {
            handleSharedMedia(value);
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
  }

  @visibleForTesting
  void handleSharedMedia(List<SharedMediaFile> files) {
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

      _lastHandledTime = now;
      _lastHandledContent = dedupKey;

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
