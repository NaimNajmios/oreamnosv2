import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

/// Dedicated local counter for the Groq query planner.
///
/// Deliberately separate from [FreeTierGuard]: that guard tracks vision calls
/// against Groq's 80/day vision budget, while planner calls are ~200 tokens
/// each and have their own allowance.
@lazySingleton
class QueryPlannerQuotaGuard {
  QueryPlannerQuotaGuard(this._prefs);

  final SharedPreferences _prefs;

  int get cap => AppConstants.groqPlannerDailyCap;

  String _key() {
    final now = DateTime.now().toUtc();
    final date =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'query_planner_groq_count_$date';
  }

  int get count => _prefs.getInt(_key()) ?? 0;

  bool get shouldSkip => count >= cap;

  /// Counts an attempted call (including a 429/timeout) so a broken key
  /// cannot spin forever.
  Future<void> record() => _prefs.setInt(_key(), count + 1);
}
