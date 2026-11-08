import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../domain/models/facebook_page_insights.dart';

/// Small prefs cache for Page performance. Tokens never enter this store.
@lazySingleton
class FacebookPageInsightsStore {
  FacebookPageInsightsStore(this._prefs);

  final SharedPreferences _prefs;

  String _key(String pageId) =>
      '${AppConstants.keyFacebookPageInsights}_$pageId';

  FacebookPageInsights? load(String pageId) {
    if (pageId.isEmpty) return null;
    try {
      final raw = _prefs.getString(_key(pageId));
      if (raw == null || raw.isEmpty) return null;
      return FacebookPageInsights.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(FacebookPageInsights insights) async {
    try {
      await _prefs.setString(
        _key(insights.pageId),
        jsonEncode(insights.toJson()),
      );
    } catch (_) {}
  }

  Future<void> clear(String pageId) async {
    try {
      await _prefs.remove(_key(pageId));
    } catch (_) {}
  }
}
