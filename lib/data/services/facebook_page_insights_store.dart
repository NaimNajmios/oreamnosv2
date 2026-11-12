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

  String _key(String pageId, int days) =>
      '${AppConstants.keyFacebookPageInsights}_${pageId}_$days';

  FacebookPageInsights? load(String pageId, {int days = 28}) {
    if (pageId.isEmpty) return null;
    try {
      var raw = _prefs.getString(_key(pageId, days));
      if ((raw == null || raw.isEmpty) && days == 28) {
        // Legacy caches predate range-scoped keys and only held 28D data.
        raw = _prefs.getString(
          '${AppConstants.keyFacebookPageInsights}_$pageId',
        );
      }
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
        _key(insights.pageId, insights.rangeDays),
        jsonEncode(insights.toJson()),
      );
    } catch (_) {}
  }

  Future<void> clear(String pageId) async {
    if (pageId.isEmpty) return;
    try {
      final prefix = '${AppConstants.keyFacebookPageInsights}_$pageId';
      final keys = _prefs
          .getKeys()
          .where((key) => key == prefix || key.startsWith('${prefix}_'))
          .toList();
      for (final key in keys) {
        await _prefs.remove(key);
      }
    } catch (_) {}
  }
}
