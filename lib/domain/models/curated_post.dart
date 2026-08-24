import 'package:equatable/equatable.dart';

/// Attribution for the original source, kept separate from body.
class SourceAttribution extends Equatable {
  final String label;
  final String? url;
  final String? domain;
  final bool isInferred;

  const SourceAttribution({
    required this.label,
    this.url,
    this.domain,
    this.isInferred = false,
  });

  factory SourceAttribution.fromJson(Map<String, dynamic> json) {
    return SourceAttribution(
      label: (json['label'] as String?)?.trim() ?? '',
      url: (json['url'] as String?)?.trim().isEmpty == true ? null : (json['url'] as String?)?.trim(),
      domain: (json['domain'] as String?)?.trim(),
      isInferred: json['isInferred'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
        'domain': domain,
        'isInferred': isInferred,
      };

  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get isEmpty => label.isEmpty && !hasUrl;

  @override
  List<Object?> get props => [label, url, domain, isInferred];
}

/// Result of web scraping, preserving metadata separately from text.
class ExtractedArticle extends Equatable {
  final String text;
  final String? pageTitle;
  final String url;
  final String domain;
  final String? description;

  const ExtractedArticle({
    required this.text,
    required this.url,
    required this.domain,
    this.pageTitle,
    this.description,
  });

  @override
  List<Object?> get props => [text, pageTitle, url, domain, description];
}

class CuratedPost extends Equatable {
  final String title;
  final String bodyMarkdown;
  final List<String> hashtags;
  final SourceAttribution source;
  final String rawMarkdown;

  const CuratedPost({
    required this.title,
    required this.bodyMarkdown,
    required this.hashtags,
    required this.source,
    required this.rawMarkdown,
  });

  /// Regex to strip emoji (broad unicode ranges).
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1FA70}-\u{1FAFF}]',
    unicode: true,
  );

  static String _stripEmoji(String s) => s.replaceAll(_emojiRegex, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  static String _normalizeHashtag(String s) {
    var t = s.trim();
    if (t.startsWith('#')) t = t.substring(1);
    t = _stripEmoji(t).replaceAll(RegExp(r'\s+'), '');
    return t;
  }

  factory CuratedPost.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['title'] as String?) ?? '';
    final rawBody = (json['body'] as String?) ?? (json['content'] as String?) ?? '';
    final rawHashtags = json['hashtags'];
    final rawSource = json['source'];

    String title = _stripEmoji(rawTitle.trim());
    // Title: single line, max 100 chars
    title = title.split('\n').first.trim();
    if (title.length > 100) title = title.substring(0, 100).trim();

    String body = _stripEmoji(rawBody.trim());
    // Remove any accidental source/hashtag block inside body
    body = body.replaceAll(RegExp(r'\n+\s*(Sumber|Source)\s*[:\-—][^\n]*$', caseSensitive: false), '').trim();
    body = body.replaceAll(RegExp(r'(\n\s*#[^\n]*)+$'), '').trim();
    body = _formatBody(body);

    List<String> hashtags = [];
    if (rawHashtags is List) {
      hashtags = rawHashtags.map((e) => _normalizeHashtag(e.toString())).where((e) => e.isNotEmpty).toList();
    } else if (rawHashtags is String) {
      hashtags = rawHashtags
          .split(RegExp(r'[,\s]+'))
          .map(_normalizeHashtag)
          .where((e) => e.isNotEmpty)
          .toList();
    }

    SourceAttribution source;
    if (rawSource is Map<String, dynamic>) {
      source = SourceAttribution.fromJson(rawSource);
    } else if (rawSource is String) {
      final s = rawSource.trim();
      source = s.isEmpty ? const SourceAttribution(label: '') : SourceAttribution(label: _stripEmoji(s));
    } else {
      source = const SourceAttribution(label: '');
    }

    // Build rawMarkdown: title + body + hashtags only (no source inside)
    final buf = StringBuffer();
    if (title.isNotEmpty) {
      buf.writeln(title);
      buf.writeln();
    }
    if (body.isNotEmpty) buf.writeln(body);
    if (hashtags.isNotEmpty) {
      if (body.isNotEmpty) buf.writeln();
      buf.write(hashtags.map((h) => '#$h').join(' '));
    }
    final rawMarkdown = buf.toString().trim();

    return CuratedPost(
      title: title,
      bodyMarkdown: body,
      hashtags: hashtags,
      source: source,
      rawMarkdown: rawMarkdown,
    );
  }

  /// Source-faithful paragraph formatter: never adds facts, only reflows existing sentences.
  /// - Keeps existing \n\n structure if already 2+ paragraphs and no paragraph is overly long (>75 words).
  /// - If single long paragraph (>70 words), splits by sentences into 2-4 balanced paragraphs (30-60 words each).
  static String _formatBody(String body) {
    if (body.isEmpty) return body;
    // Preserve bullet lists as-is
    if (body.contains(RegExp(r'^\s*[-•]\s', multiLine: true))) return body;
    final existingParas = body.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();
    if (existingParas.length >= 2) {
      // If no paragraph is too long, keep original structure (source-faithful).
      final maxWords = existingParas.map((p) => p.trim().split(RegExp(r'\s+')).length).reduce((a, b) => a > b ? a : b);
      if (maxWords <= 75) return body.trim();
      // Otherwise reflow: flatten and re-split below
    }
    final totalWords = body.trim().split(RegExp(r'\s+')).length;
    if (totalWords <= 70 && existingParas.length == 1) return body.trim();

    // Single long paragraph -> split by sentences, preserve content exactly.
    final sentences = body
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sentences.length <= 2) return body.trim();

    // Target 2-4 paragraphs, 30-60 words each, balanced.
    int targetParas;
    if (totalWords <= 90) {
      targetParas = 2;
    } else if (totalWords <= 150) {
      targetParas = 3;
    } else {
      targetParas = 4;
    }
    targetParas = targetParas.clamp(2, 4);
    // Avoid creating more paras than sentences
    if (sentences.length < targetParas) targetParas = sentences.length;

    final wordsPerPara = (totalWords / targetParas).ceil();
    final List<String> paras = [];
    final List<String> current = [];
    int currentWords = 0;
    for (final s in sentences) {
      final w = s.trim().split(RegExp(r'\s+')).length;
      if (current.isNotEmpty && currentWords + w > wordsPerPara + 12 && paras.length < targetParas - 1) {
        paras.add(current.join(' ').trim());
        current.clear();
        currentWords = 0;
      }
      current.add(s.trim());
      currentWords += w;
    }
    if (current.isNotEmpty) paras.add(current.join(' ').trim());
    // If we ended with too many paras, merge smallest neighbours
    while (paras.length > targetParas) {
      // merge last two
      final last = paras.removeLast();
      paras[paras.length - 1] = '${paras.last} $last';
    }
    return paras.join('\n\n').trim();
  }

  /// Fallback when LLM returns plain markdown instead of JSON.
  factory CuratedPost.fromMarkdownFallback(String markdown, {SourceAttribution? source}) {
    var text = _stripEmoji(markdown.trim());
    if (text.isEmpty) {
      return CuratedPost(
        title: '',
        bodyMarkdown: '',
        hashtags: [],
        source: source ?? const SourceAttribution(label: ''),
        rawMarkdown: '',
      );
    }

    // Extract trailing hashtags
    final hashtagRegex = RegExp(r'(\n\s*#[^\n]*)+$');
    final hashtagBlock = hashtagRegex.firstMatch(text)?.group(0) ?? '';
    final hashtagList = RegExp(r'#([^\s#]+)').allMatches(hashtagBlock).map((m) => _normalizeHashtag(m.group(1)!)).where((e) => e.isNotEmpty).toList();
    text = text.replaceAll(hashtagRegex, '').trim();
    text = text.replaceAll(RegExp(r'\n+(#[^\s#]+\s*)+$'), '').trim();

    // Extract source line if present (but keep separate)
    SourceAttribution resolvedSource = source ?? const SourceAttribution(label: '');
    final sourceRegex = RegExp(r'\n+\s*(Sumber|Source)\s*[:\-—][^\n]*$', caseSensitive: false);
    final sourceMatch = sourceRegex.firstMatch(text);
    if (sourceMatch != null) {
      final sourceLine = sourceMatch.group(0)!.trim();
      // Try to extract URL from source line
      final urlRegex = RegExp(r'https?://[^\s]+');
      final urlMatch = urlRegex.firstMatch(sourceLine);
      resolvedSource = SourceAttribution(
        label: _stripEmoji(sourceLine.replaceAll(urlRegex, '').replaceAll(RegExp(r'^(Sumber|Source)\s*[:\-—]\s*', caseSensitive: false), '').trim()),
        url: urlMatch?.group(0),
        domain: urlMatch != null ? Uri.tryParse(urlMatch.group(0)!)?.host : null,
      );
      text = text.replaceAll(sourceRegex, '').trim();
    }

    // Title is first line if it looks like heading/bold or first line <100 chars and remaining text is longer
    String title = '';
    String body = text;
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      final first = lines.first.trim().replaceAll(RegExp(r'^#+\s*'), '').replaceAll(RegExp(r'^\*\*|\*\*$'), '').trim();
      if (first.isNotEmpty && first.length <= 120 && text.length > first.length + 20) {
        // Heuristic: treat first line as title if next lines exist
        title = _stripEmoji(first);
        if (title.length > 100) title = title.substring(0, 100).trim();
        body = lines.skip(1).join('\n').trim().replaceAll(RegExp(r'^\n+'), '');
      }
    }
    body = _formatBody(body);

    final buf = StringBuffer();
    if (title.isNotEmpty) {
      buf.writeln(title);
      buf.writeln();
    }
    if (body.isNotEmpty) buf.writeln(body);
    if (hashtagList.isNotEmpty) {
      if (body.isNotEmpty) buf.writeln();
      buf.write(hashtagList.map((h) => '#$h').join(' '));
    }

    return CuratedPost(
      title: title,
      bodyMarkdown: body,
      hashtags: hashtagList,
      source: resolvedSource,
      rawMarkdown: buf.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': bodyMarkdown,
        'hashtags': hashtags,
        'source': source.toJson(),
        'rawMarkdown': rawMarkdown,
      };

  /// Markdown filtered by toggles: title/hashtags/source.
  /// Source is NOT inside rawMarkdown; when showSource is true, caller should render source card separately.
  /// For copy, we optionally append source url if requested.
  String toMarkdownFiltered({bool showTitle = true, bool showHashtags = true, bool showSource = false, bool appendSourceForCopy = false}) {
    final buf = StringBuffer();
    if (showTitle && title.isNotEmpty) {
      buf.writeln(title);
      buf.writeln();
    }
    if (bodyMarkdown.isNotEmpty) buf.writeln(bodyMarkdown);
    if (showHashtags && hashtags.isNotEmpty) {
      if (bodyMarkdown.isNotEmpty) buf.writeln();
      buf.write(hashtags.map((h) => '#$h').join(' '));
    }
    if (appendSourceForCopy && showSource && source.hasUrl) {
      buf.writeln();
      buf.writeln();
      buf.write('Sumber: ${source.url}');
    } else if (appendSourceForCopy && showSource && source.label.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write('Sumber: ${source.label}');
    }
    return buf.toString().trim();
  }

  /// For card generator: body only
  String get bodyForCard => bodyMarkdown;

  @override
  List<Object?> get props => [title, bodyMarkdown, hashtags, source, rawMarkdown];
}
