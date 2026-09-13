import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  StreamSubscription? _intentDataStreamSubscription;
  DateTime? _lastHandledTime;
  String? _lastHandledContent;

  /// Callback fired when new text or URL is shared to the app
  Function(String)? onSharedTextReceived;

  void initialize() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            handleSharedMedia(value);
            // Clear the stream intent cache so warm resumptions don't replay stale data
            try {
              ReceiveSharingIntent.instance.reset();
            } catch (_) {}
          },
          onError: (err) {
            debugPrint("getMediaStream error: $err");
          },
        );

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
          handleSharedMedia(value);
          // Tell the library that we are done processing the initial intent
          try {
            ReceiveSharingIntent.instance.reset();
          } catch (_) {}
        })
        .catchError((err) {
          debugPrint("getInitialMedia error: $err");
        });
  }

  @visibleForTesting
  void resetDeduplicationForTesting() {
    _lastHandledTime = null;
    _lastHandledContent = null;
  }

  @visibleForTesting
  void handleSharedMedia(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    final file = files.first;

    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      final content = file.path.trim();
      if (content.isEmpty) return;

      // Debounce duplicate events within 1500ms (common on Android resume/stream rebroadcasts)
      final now = DateTime.now();
      if (_lastHandledContent == content &&
          _lastHandledTime != null &&
          now.difference(_lastHandledTime!) <
              const Duration(milliseconds: 1500)) {
        debugPrint("Ignoring duplicate share intent event: $content");
        return;
      }

      _lastHandledTime = now;
      _lastHandledContent = content;

      if (onSharedTextReceived != null) {
        onSharedTextReceived!(content);
      }
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
