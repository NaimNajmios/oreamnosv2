import '../models/card_data.dart';

/// Picks the word that gets set in giant outlined type behind a cutout.
abstract final class GiantTextSource {
  static String? forCardData(CardData? data) {
    if (data == null) return null;
    if (data is PlayerSpotlight) {
      return _lastWord(data.playerName);
    }
    if (data is HeadlineQuote) {
      return _lastWord(data.headline);
    }
    return null;
  }

  static String? _lastWord(String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return null;
    final word = words.last.replaceAll(
      RegExp(r'[^\p{L}\p{N}]', unicode: true),
      '',
    );
    return word.isEmpty ? null : word.toUpperCase();
  }
}
