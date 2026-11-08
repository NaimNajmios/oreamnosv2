import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';

/// Generated content waiting to be published, derived from the Generate tab.
class PublishHandoff {
  const PublishHandoff({
    required this.fingerprint,
    required this.text,
    required this.title,
    required this.uppercaseTitle,
    required this.hashtagCount,
    required this.sourceUrl,
    required this.createdAt,
  });

  final String fingerprint;
  final String text;
  final String title;
  final bool uppercaseTitle;
  final int hashtagCount;
  final String sourceUrl;
  final DateTime createdAt;

  String get snippet {
    final first = text
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    return first.length > 140 ? '${first.substring(0, 140)}…' : first;
  }
}

final publishHandoffProvider =
    NotifierProvider<PublishHandoffNotifier, PublishHandoff?>(
      PublishHandoffNotifier.new,
    );

/// Mirrors the Cards tab behaviour: content generated in the Generate tab is
/// immediately available in Publish without passing router `extra`.
class PublishHandoffNotifier extends Notifier<PublishHandoff?> {
  String? _consumedFingerprint;
  String? _lastFingerprint;
  DateTime _createdAt = DateTime.now();

  @override
  PublishHandoff? build() {
    final ui = ref.watch(generateViewModelProvider);
    final post = ui.curatedPost;
    if (post == null) return null;

    final text = post.toPlainTextFiltered(
      showTitle: ui.showTitle,
      uppercaseTitle: ui.uppercaseTitle,
      showHashtags: ui.showHashtags,
      showSource: ui.showSource,
      appendSourceForCopy: true,
    );
    if (text.trim().isEmpty) return null;

    final fingerprint = [
      post.rawMarkdown,
      ui.showTitle,
      ui.uppercaseTitle,
      ui.showHashtags,
      ui.showSource,
    ].join('\u0001');
    if (fingerprint == _consumedFingerprint) return null;
    if (fingerprint != _lastFingerprint) {
      _lastFingerprint = fingerprint;
      _createdAt = DateTime.now();
    }

    return PublishHandoff(
      fingerprint: fingerprint,
      text: text,
      title: post.title,
      uppercaseTitle: ui.showTitle && ui.uppercaseTitle,
      hashtagCount: ui.showHashtags ? post.hashtags.length : 0,
      sourceUrl: post.source.url ?? '',
      createdAt: _createdAt,
    );
  }

  /// Called after a successful publish or an explicit dismiss. The generated
  /// post stays in the Generate tab; only the Publish handoff is cleared.
  void consume() {
    _consumedFingerprint = state?.fingerprint;
    state = null;
  }

  /// A brand-new generation should surface again even if the previous
  /// fingerprint was consumed.
  void markFresh() {
    _consumedFingerprint = null;
    _createdAt = DateTime.now();
    ref.invalidateSelf();
  }
}
