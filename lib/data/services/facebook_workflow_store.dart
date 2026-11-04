import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_publish_workflow.dart';

/// Persists custom publishing workflows and per-Page defaults. Tokens never
/// enter this store.
@lazySingleton
class FacebookWorkflowStore {
  static const int maxCustomWorkflows = 10;

  FacebookWorkflowStore(this._prefs);

  final SharedPreferences _prefs;

  List<FacebookPublishWorkflow> get customWorkflows {
    final raw = _prefs.getString(AppConstants.keyFacebookWorkflows);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (e) => FacebookPublishWorkflow.fromJson(e.cast<String, dynamic>()),
          )
          .where((w) => w.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<FacebookPublishWorkflow> get allWorkflows => [
    ...FacebookPublishWorkflow.builtIns,
    ...customWorkflows,
  ];

  List<FacebookPublishWorkflow> forPage(String pageId) {
    return allWorkflows
        .where((w) => w.pageId.isEmpty || w.pageId == pageId)
        .toList(growable: false);
  }

  FacebookPublishWorkflow? byId(String id) {
    for (final workflow in allWorkflows) {
      if (workflow.id == id) return workflow;
    }
    return null;
  }

  String _defaultKey(String pageId) =>
      '${AppConstants.keyFacebookDefaultWorkflowPrefix}$pageId';

  FacebookPublishWorkflow defaultForPage(String pageId) {
    final id = _prefs.getString(_defaultKey(pageId));
    if (id != null) {
      final workflow = byId(id);
      if (workflow != null) return workflow;
    }
    return FacebookPublishWorkflow.builtIns.first;
  }

  Future<void> setDefaultForPage(String pageId, String workflowId) async {
    await _prefs.setString(_defaultKey(pageId), workflowId);
  }

  Future<void> clearDefaultForPage(String pageId) async {
    await _prefs.remove(_defaultKey(pageId));
  }

  Future<void> save(FacebookPublishWorkflow workflow) async {
    final records = [...customWorkflows];
    final index = records.indexWhere((w) => w.id == workflow.id);
    final stamped = workflow.copyWith(updatedAt: DateTime.now());
    if (index < 0) {
      records.insert(0, stamped);
    } else {
      records[index] = stamped;
    }
    final capped = records.take(maxCustomWorkflows).toList();
    await _prefs.setString(
      AppConstants.keyFacebookWorkflows,
      jsonEncode(capped.map((w) => w.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final records = customWorkflows.where((w) => w.id != id).toList();
    await _prefs.setString(
      AppConstants.keyFacebookWorkflows,
      jsonEncode(records.map((w) => w.toJson()).toList()),
    );
    // Clear defaults that pointed at the deleted workflow.
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(AppConstants.keyFacebookDefaultWorkflowPrefix)) {
        continue;
      }
      if (_prefs.getString(key) == id) await _prefs.remove(key);
    }
  }
}
