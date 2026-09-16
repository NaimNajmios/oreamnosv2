import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/data/models/ai_provider.dart';

/// Local quota guard: stays at ~60% of real free-tier limits so mid-flow
/// 429s become clean pre-planned provider hops instead of errors.
@lazySingleton
class FreeTierGuard {
  FreeTierGuard(this._prefs);

  final SharedPreferences _prefs;

  static const Map<String, int> dailyCaps = {
    'gemini': 200,
    'groq': 80,
    'openrouter': 40,
  };

  static String _dateKey() {
    final now = DateTime.now().toUtc();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _prefKey(AiProvider provider) =>
      'vision_count_${provider.name}_${_dateKey()}';

  int count(AiProvider provider) => _prefs.getInt(_prefKey(provider)) ?? 0;

  int capFor(AiProvider provider) => dailyCaps[provider.name] ?? 40;

  /// True when [provider] should be skipped before attempting a request.
  bool shouldSkip(AiProvider provider) => count(provider) >= capFor(provider);

  Future<void> record(AiProvider provider) async {
    final key = _prefKey(provider);
    await _prefs.setInt(key, count(provider) + 1);
  }

  /// First provider in [chain] that has not hit its local cap, or null.
  AiProvider? firstAvailable(List<AiProvider> chain) {
    for (final p in chain) {
      if (!shouldSkip(p)) return p;
    }
    return null;
  }
}
