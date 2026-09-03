/// Central policy for source attribution hardening.
///
/// Rule: `source.label` must NEVER originate from a URL, domain, platform
/// name (X/Twitter), or bare account handle. It must be an outlet/portal
/// name taken from content (article body / `og:site_name` / tweet text),
/// optionally formatted as "[Outlet] via [Author Display Name]" for tweets.
///
/// `source.url` may still be stored internally (Open/Copy buttons) but must
/// never be displayed as the citation label.
class SourcePolicy {
  const SourcePolicy._();

  static final RegExp _platformOnly = RegExp(
    r'^(x|x\.com|twitter|twitter\.com|x\s*/\s*twitter|twitter\s*/\s*x|t\.co)$',
    caseSensitive: false,
  );

  static final RegExp _urlLike = RegExp(
    r'(https?://|www\.|x\.com|twitter\.com|t\.co)',
    caseSensitive: false,
  );

  static final RegExp _bareDomain = RegExp(
    r'^\S+\.[a-z]{2,6}(/\S*)?$',
    caseSensitive: false,
  );

  static final RegExp _handleOnly = RegExp(r'^@?[A-Za-z0-9_]{1,30}$');

  static final RegExp _viaPlatformSuffix = RegExp(
    r'\s+via\s+(x|x\.com|twitter|twitter\.com|t\.co)$',
    caseSensitive: false,
  );

  /// True for pure platform tokens: X, Twitter, x.com, twitter.com, t.co.
  static bool isPlatformOnly(String s) => _platformOnly.hasMatch(s.trim());

  /// True if the string looks like a URL / domain reference.
  static bool isUrlLike(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.contains('://')) return true;
    if (_urlLike.hasMatch(t)) return true;
    // Bare domain without spaces (e.g. bbc.com, www.bbc.com/sport).
    if (!t.contains(' ') && _bareDomain.hasMatch(t)) return true;
    return false;
  }

  /// True for bare handles: "@FabrizioRomano" or "FabrizioRomano"
  /// (single token, no spaces). Display names contain spaces and return false.
  static bool isHandleOnly(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.contains(' ') || t.contains('.')) return false;
    return _handleOnly.hasMatch(t);
  }

  /// Sanitizes a candidate label. Returns "" when the label is not a valid
  /// outlet citation (URL, domain, platform, handle-alone).
  ///
  /// [authorDisplayName] is used to repair "Outlet via @handle" into
  /// "Outlet via Display Name". If only a handle is known (no display name),
  /// the via-suffix is dropped and the outlet alone is returned.
  static String sanitizeLabel(String? label, {String? authorDisplayName}) {
    var t = (label ?? '').trim();
    if (t.isEmpty) return '';
    // Strip trailing "via X/Twitter/x.com".
    t = t.replaceAll(_viaPlatformSuffix, '').trim();
    if (t.isEmpty) return '';

    // Normalize "Outlet via @handle" -> "Outlet via DisplayName" (or outlet).
    final viaMatch = RegExp(
      r'^(.*?)\s+via\s+(@?[A-Za-z0-9_]{1,30})$',
      caseSensitive: false,
    ).firstMatch(t);
    if (viaMatch != null) {
      final outlet = viaMatch.group(1)!.trim();
      if (isUrlLike(outlet) || isPlatformOnly(outlet)) return '';
      final display = (authorDisplayName ?? '').trim();
      if (display.isNotEmpty &&
          !isUrlLike(display) &&
          !isPlatformOnly(display)) {
        t = '$outlet via $display';
      } else {
        t = outlet;
      }
    }

    if (isPlatformOnly(t)) return '';
    if (isUrlLike(t)) return '';
    // Single-token handle with no outlet (e.g. "@FabrizioRomano").
    if (t.startsWith('@') && isHandleOnly(t)) return '';
    if (isHandleOnly(t) && !_looksLikeOutlet(t)) return '';
    // Any remaining URL fragment disqualifies the whole label.
    if (t.contains('http') || t.contains('www.')) return '';
    return t;
  }

  static bool _looksLikeOutlet(String singleToken) {
    // Single capitalized token like "BBC" could be an outlet acronym;
    // without more signal we treat short all-caps tokens as outlets only
    // when they contain no handle marker. Callers pass handles with "@"
    // stripped already, so be conservative: reject single tokens unless
    // they were part of an "Outlet via X" construct (handled above).
    return false;
  }

  /// Heuristic extraction of the original outlet from tweet text.
  /// Returns null when no outlet is identifiable (caller must leave label "").
  /// Never returns a URL, platform name, or handle.
  static String? extractOutletFromTweet(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    // Explicit "Sumber:/Source:" marker inside tweet.
    final sourceMarker = RegExp(
      r'(?:sumber|source)\s*[:\-—]\s*([^\n@#https://]+)',
      caseSensitive: false,
    ).firstMatch(t);
    if (sourceMarker != null) {
      final candidate = _cleanOutlet(sourceMarker.group(1)!);
      if (candidate != null) return candidate;
    }
    // "according to X", "per X", "via X", "laporan X", "menurut X".
    final patterns = [
      RegExp(
        r'according to\s+([A-Z][A-Za-z&.\- ]{1,60})',
        caseSensitive: false,
      ),
      RegExp(r'\bper\s+([A-Z][A-Za-z&.\- ]{1,60})', caseSensitive: false),
      RegExp(r'\bvia\s+([A-Z][A-Za-z&.\- ]{1,60})', caseSensitive: false),
      RegExp(r'laporan\s+([A-Z][A-Za-z&.\- ]{1,60})', caseSensitive: false),
      RegExp(r'menurut\s+([A-Z][A-Za-z&.\- ]{1,60})', caseSensitive: false),
      RegExp(
        r'seperti dilaporkan\s+([A-Z][A-Za-z&.\- ]{1,60})',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(t);
      if (m != null) {
        final candidate = _cleanOutlet(m.group(1)!);
        if (candidate != null) return candidate;
      }
    }
    // Leading "OUTLET: ..." prefix (e.g. "BBC: ...", "Astro Arena: ...").
    final prefix = RegExp(r'^([A-Z][A-Za-z&.\- ]{1,40})\s*:\s+').firstMatch(t);
    if (prefix != null) {
      final candidate = _cleanOutlet(prefix.group(1)!);
      if (candidate != null) return candidate;
    }
    return null;
  }

  static String? _cleanOutlet(String raw) {
    var t = raw.trim();
    // Cut at sentence boundary / handle / url / hashtag.
    t = t.split(RegExp(r'[.,;!|\n]')).first.trim();
    t = t.split('@').first.trim();
    t = t.split('#').first.trim();
    t = t.split('http').first.trim();
    // Drop trailing twitter-style "via ..." already handled.
    t = t.replaceAll(_viaPlatformSuffix, '').trim();
    if (t.isEmpty) return null;
    if (isPlatformOnly(t) || isUrlLike(t)) return null;
    final handleCandidate = t.startsWith('@') ? t : '@$t';
    if (isHandleOnly(handleCandidate) && !t.contains(' ')) return null;
    // Require at least 2 chars; single words like "BBC" allowed.
    if (t.length < 2) return null;
    // Cap length to avoid swallowing sentences.
    if (t.length > 60) t = t.substring(0, 60).trim();
    return t.isEmpty ? null : t;
  }
}
