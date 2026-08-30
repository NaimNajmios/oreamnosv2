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

  /// Splits excessively long paragraphs into smaller ones to improve readability.
  /// Paragraphs exceeding [maxWordsPerParagraph] are split at sentence boundaries.
  static String splitLongParagraphs(
    String text, {
    int maxWordsPerParagraph = 40,
  }) {
    if (text.trim().isEmpty) return text;

    // Split by newlines while preserving them
    final paragraphs = text.split('\n');
    final result = <String>[];

    for (var paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) {
        result.add(paragraph);
        continue;
      }

      final words = countWords(paragraph);
      if (words <= maxWordsPerParagraph) {
        result.add(paragraph);
        continue;
      }

      // Tokenize into sentences
      final matches = RegExp(r'[^.!?]+[.!?]+').allMatches(paragraph);
      if (matches.isEmpty) {
        result.add(paragraph);
        continue;
      }

      List<String> sentences = [];
      int lastEnd = 0;
      for (var match in matches) {
        sentences.add(paragraph.substring(lastEnd, match.end).trim());
        lastEnd = match.end;
      }
      if (lastEnd < paragraph.length) {
        final remaining = paragraph.substring(lastEnd).trim();
        if (remaining.isNotEmpty) sentences.add(remaining);
      }

      String currentPara = "";
      int currentWordCount = 0;
      List<String> subParagraphs = [];

      for (var sentence in sentences) {
        final sentenceWords = countWords(sentence);
        if (currentPara.isEmpty) {
          currentPara = sentence;
          currentWordCount = sentenceWords;
        } else {
          if (currentWordCount + sentenceWords > maxWordsPerParagraph) {
            subParagraphs.add(currentPara);
            currentPara = sentence;
            currentWordCount = sentenceWords;
          } else {
            currentPara += ' $sentence';
            currentWordCount += sentenceWords;
          }
        }
      }
      if (currentPara.isNotEmpty) {
        subParagraphs.add(currentPara);
      }

      // Join sub-paragraphs with double newline
      result.add(subParagraphs.join('\n\n'));
    }

    return result.join('\n');
  }
}
