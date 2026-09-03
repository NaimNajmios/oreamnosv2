/// Port of Android `ResponseCleanup` — post-processing for markdown-fallback
/// curator output (the structured JSON-schema flow bypasses cleanup).
class ResponseCleanup {
  const ResponseCleanup._();

  static final RegExp horizontalRulePattern = RegExp(
    r'^-{3,}\s*$',
    multiLine: true,
  );
  static final RegExp multipleNewlinesPattern = RegExp(r'\n\s*\n\s*\n+');
  static final RegExp horizontalWhitespacePattern = RegExp(r'[ \t]+');
  static final RegExp sourceCitationPattern = RegExp(
    r'^[\s]*[*_]*(?:Sumber|Source)[\s*_]*[:：].*$',
    multiLine: true,
    caseSensitive: false,
  );
  static final RegExp trailingNewlinesPattern = RegExp(r'\n+$');
  static final RegExp bulletPointPattern = RegExp(
    '^(\\s*)[-*>\u2022\u25e6\u25aa\u25ab\u2023\u2043](\\s+)',
    multiLine: true,
  );
  static final RegExp asteriskTextPattern = RegExp(r'\*+(.*?)\*+');

  static const List<String> unwantedPhrases = [
    'Okay, ini percubaan untuk mengubah teks tersebut',
    'terjemahkan ke Bahasa Melayu (Malaysia)',
    'suntikkan sedikit gaya yang kurang formal',
    'istilah bola sepak Inggeris yang biasa',
    'Saya cuba gunakan perkataan yang lebih santai',
    'Saya juga masukkan istilah bola sepakt',
    'Struktur diubah dengan menggabungkan',
    'Em dash (—) dibuang seperti yang diminta',
    'Tukar perkataan dari bahasa inggeris',
    'Semoga ini membantu',
    'Saya cuba',
    'Saya juga',
    'Struktur diubah',
    'Em dash',
    'Tukar perkataan',
    'Semoga ini',
  ];

  static String removeSourceCitation(String? text) {
    if (text == null || text.isEmpty) return text ?? '';
    final cleaned = text.replaceAll(sourceCitationPattern, '');
    return cleaned.replaceAll(trailingNewlinesPattern, '').trim();
  }

  static String cleanUpResponse(String? response) {
    if (response == null || response.trim().isEmpty) return response ?? '';
    var cleaned = response.trim();
    cleaned = cleaned.replaceAll(horizontalRulePattern, '');
    for (final phrase in unwantedPhrases) {
      cleaned = cleaned.replaceAll(phrase, '');
    }
    cleaned = cleaned.replaceAllMapped(
      bulletPointPattern,
      (m) => '${m.group(1)}•${m.group(2)}',
    );
    cleaned = cleaned.replaceAll(multipleNewlinesPattern, '\n\n');
    cleaned = cleaned.replaceAll(horizontalWhitespacePattern, ' ');
    cleaned = cleaned.trim();
    // Guard: never return a stub shorter than 50 chars.
    if (cleaned.length < 50) return response;
    return cleaned;
  }

  static String cleanUpResponseWithMarkdown(String? response) {
    final cleaned = cleanUpResponse(response);
    return cleaned.replaceAllMapped(
      asteriskTextPattern,
      (m) => m.group(1) ?? '',
    );
  }
}
