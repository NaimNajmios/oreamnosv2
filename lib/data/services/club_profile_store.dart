import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/club_profile.dart';

/// Persists the user's club setup locally. No club assets ship with the app.
@lazySingleton
class ClubProfileStore {
  ClubProfileStore(this._prefs);

  static const String _key = 'card_club_profile';
  final SharedPreferences _prefs;

  ClubProfile? load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return ClubProfile.fromJson(json);
    } catch (_) {}
    return null;
  }

  Future<bool> save(ClubProfile profile) =>
      _prefs.setString(_key, jsonEncode(profile.toJson()));

  Future<bool> clear() => _prefs.remove(_key);
}
