import 'url_detector.dart';

class ParsedSharedContent {
  final String? primaryUrl;
  final UrlType urlType;
  final String accompanyingText;
  final bool isPureUrl;
  final String originalInput;

  const ParsedSharedContent({
    this.primaryUrl,
    required this.urlType,
    this.accompanyingText = '',
    this.isPureUrl = false,
    required this.originalInput,
  });

  /// Recommended display text for input controllers.
  /// If it's a pure URL, displays the clean URL. If there is commentary + URL,
  /// returns the sanitized input.
  String get displayInput {
    if (isPureUrl && primaryUrl != null) {
      return primaryUrl!;
    }
    if (primaryUrl != null && accompanyingText.isNotEmpty) {
      return '$accompanyingText\n$primaryUrl'.trim();
    }
    return originalInput.trim();
  }
}

class SharedContentParser {
  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s<>"]+|www\.[^\s<>"]+|(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}(?:\/[^\s<>"]*)?)',
    caseSensitive: false,
  );

  static const Set<String> _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    's',
    't',
    'ref_src',
    'ref_url',
    'fbclid',
    'gclid',
    'igshid',
    'si',
  };

  /// Parses raw shared or pasted text to detect and extract primary URLs,
  /// strip tracking parameters, and capture accompanying text.
  static ParsedSharedContent parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ParsedSharedContent(
        urlType: UrlType.notUrl,
        originalInput: '',
      );
    }

    final matches = _urlRegex.allMatches(trimmed);
    if (matches.isEmpty) {
      return ParsedSharedContent(
        urlType: UrlType.notUrl,
        accompanyingText: trimmed,
        originalInput: trimmed,
      );
    }

    // Find the first valid URL candidate
    String? foundUrl;
    Match? foundMatch;
    for (final match in matches) {
      final rawCandidate = match.group(0)!;
      final cleanCandidate = _cleanTrailingPunctuation(rawCandidate);
      final normalized = _ensureScheme(cleanCandidate);
      final uri = Uri.tryParse(normalized);
      if (uri != null && uri.hasAuthority && uri.host.contains('.')) {
        foundUrl = cleanCandidate;
        foundMatch = match;
        break;
      }
    }

    if (foundUrl == null || foundMatch == null) {
      return ParsedSharedContent(
        urlType: UrlType.notUrl,
        accompanyingText: trimmed,
        originalInput: trimmed,
      );
    }

    // Strip tracking parameters
    final cleanUrl = sanitizeUrl(foundUrl);
    final urlType = UrlDetector.classifyUrl(cleanUrl);

    // Extract surrounding text
    final beforeText = trimmed.substring(0, foundMatch.start).trim();
    final afterText = trimmed.substring(foundMatch.end).trim();
    final parts = [beforeText, afterText].where((p) => p.isNotEmpty).toList();
    final accompanyingText = parts.join(' ').trim();

    final isPure = accompanyingText.isEmpty;

    return ParsedSharedContent(
      primaryUrl: cleanUrl,
      urlType: urlType,
      accompanyingText: accompanyingText,
      isPureUrl: isPure,
      originalInput: trimmed,
    );
  }

  /// Removes tracking parameters (utm_*, s, t, etc.) from a URL while preserving
  /// functional parameters.
  static String sanitizeUrl(String rawUrl) {
    var urlToParse = _cleanTrailingPunctuation(rawUrl.trim());
    final hasScheme =
        urlToParse.toLowerCase().startsWith('http://') ||
        urlToParse.toLowerCase().startsWith('https://');
    if (!hasScheme) {
      urlToParse = 'https://$urlToParse';
    }

    final uri = Uri.tryParse(urlToParse);
    if (uri == null) return rawUrl;

    final filteredParams = Map<String, String>.from(uri.queryParameters);
    filteredParams.removeWhere(
      (key, _) => _trackingParams.contains(key.toLowerCase()),
    );

    final cleanUri = filteredParams.isEmpty
        ? uri.replace(query: '')
        : uri.replace(queryParameters: filteredParams);

    var result = cleanUri.toString();
    if (result.endsWith('?')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String _cleanTrailingPunctuation(String url) {
    var u = url;
    while (u.isNotEmpty &&
        (u.endsWith('.') ||
            u.endsWith(',') ||
            u.endsWith(')') ||
            u.endsWith(']') ||
            u.endsWith('!') ||
            u.endsWith('?') ||
            u.endsWith(';') ||
            u.endsWith('"') ||
            u.endsWith("'"))) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static String _ensureScheme(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return url;
    return 'https://$url';
  }
}
