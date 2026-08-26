import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  StreamSubscription? _intentDataStreamSubscription;

  /// Callback fired when new text or URL is shared to the app
  Function(String)? onSharedTextReceived;

  void initialize() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            _handleSharedMedia(value);
          },
          onError: (err) {
            debugPrint("getMediaStream error: $err");
          },
        );

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
          _handleSharedMedia(value);
          // Tell the library that we are done processing the initial intent
          ReceiveSharingIntent.instance.reset();
        })
        .catchError((err) {
          debugPrint("getInitialMedia error: $err");
        });
  }

  void _handleSharedMedia(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    // We only care about text/urls for now.
    // ReceiveSharingIntent puts text/urls in the path or type property depending on version.
    // In version 1.9.0, text is usually in path or message.
    final file = files.first;

    // According to 1.9.0 docs, if type is text, the content is in path.
    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      final content = file.path;
      if (content.isNotEmpty && onSharedTextReceived != null) {
        onSharedTextReceived!(content);
      }
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
