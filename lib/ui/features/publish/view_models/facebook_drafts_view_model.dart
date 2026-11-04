import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_draft_store.dart';

final facebookDraftsProvider =
    NotifierProvider<FacebookDraftsNotifier, List<FacebookDraftRecord>>(
      FacebookDraftsNotifier.new,
    );

/// Reactive view of saved drafts for the Publish hub. Refresh after returning
/// from the composer/drafts screens.
class FacebookDraftsNotifier extends Notifier<List<FacebookDraftRecord>> {
  late final FacebookDraftStore _store;

  @override
  List<FacebookDraftRecord> build() {
    _store = getIt<FacebookDraftStore>();
    return _store.loadAll();
  }

  void refresh() {
    state = _store.loadAll();
  }

  Future<void> delete(String id) async {
    await _store.delete(id);
    refresh();
  }
}
