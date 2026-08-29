class ReadabilityUtils {
  /// Counts the total number of words in a text.
  static int countWords(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 0;
    }
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Calculates the Flesch-Kincaid Grade Level of the text.
  static double calculateFleschKincaidGradeLevel(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 0.0;
    }

    final words = countWords(text);
    if (words == 0) return 0.0;

    // Approximate sentences by counting period, exclamation mark, question mark, or newline.
    // If none exist, we assume it's at least 1 sentence.
    var sentences = RegExp(r'[.!?\n]+').allMatches(text).length;
    if (sentences == 0) sentences = 1;

    final syllables = _countSyllables(text);

    // Flesch-Kincaid Grade Level Formula
    // 0.39 * (total words / total sentences) + 11.8 * (total syllables / total words) - 15.59
    final score =
        0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59;
    return score < 0 ? 0.0 : double.parse(score.toStringAsFixed(1));
  }

  static int _countSyllables(String text) {
    if (text.trim().isEmpty) return 0;
    final words = text.trim().split(RegExp(r'\s+'));
    var count = 0;
    for (var word in words) {
      count += _countSyllablesInWord(word);
    }
    return count;
  }

  static int _countSyllablesInWord(String word) {
    word = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (word.isEmpty) return 0;
    if (word.length <= 3) return 1;

    word = word.replaceAll(RegExp(r'(?:[^laeiouy]es|ed|[^laeiouy]e)$'), '');
    word = word.replaceAll(RegExp(r'^y'), '');

    final matches = RegExp(r'[aeiouy]{1,2}').allMatches(word).length;
    return matches == 0 ? 1 : matches;
  }
}
