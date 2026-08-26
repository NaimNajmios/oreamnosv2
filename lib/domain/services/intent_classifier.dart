enum InputIntent {
  fullArticle,
  url,
  shortQuery,
}

class IntentClassifier {
  static InputIntent classify(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return InputIntent.url;
    }
    if (trimmed.length < 300 && !trimmed.contains('\n\n')) {
      return InputIntent.shortQuery;
    }
    return InputIntent.fullArticle;
  }
}
