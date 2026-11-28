import '../../config/constants.dart';
import '../models/tavily_search.dart';
import 'football_search_lexicon.dart';

/// One query plus the Tavily parameters chosen for it.
class PlannedQuery {
  const PlannedQuery({
    required this.query,
    required this.options,
    this.isAlternative = false,
  });

  final String query;
  final SearchOptions options;
  final bool isAlternative;
}

/// Deterministic description of what the app is looking for.
class SearchPlan {
  const SearchPlan({
    required this.headline,
    required this.entities,
    required this.intent,
    required this.queries,
    this.keyEntity,
  });

  final String headline;
  final List<String> entities;
  final String intent;
  final List<PlannedQuery> queries;

  /// The one name a result must mention to be about the same story.
  /// Multi-word person names win over single-word clubs.
  final String? keyEntity;

  PlannedQuery get primary => queries.first;

  List<PlannedQuery> get alternatives =>
      queries.where((q) => q.isAlternative).toList();
}

/// Turns pasted text into 1–3 focused queries.
///
/// The old implementation took the first sentence and appended `" stats"`,
/// which is how an unrelated result could outrank the actual story. This
/// planner prefers the page headline/description, extracts known entities and
/// only adds an intent keyword when it actually applies.
class SearchQueryPlanner {
  const SearchQueryPlanner();

  SearchPlan plan({
    required String text,
    String? pageTitle,
    String? description,
  }) {
    final cleaned = _clean(text);
    final headline = _headline(cleaned, pageTitle, description);
    final signal = '$headline ${_firstChars(cleaned, 400)}';
    return _build(
      cleaned: cleaned,
      headline: headline,
      signal: signal,
      entities: _entities(signal, headline),
    );
  }

  /// Builds a plan from AI-suggested entities/queries. Option selection and
  /// the trusted-domain fallback stay deterministic and identical to the
  /// heuristic path; only the names/queries are borrowed from the AI step.
  SearchPlan planWith({
    required String text,
    required List<String> entities,
    required List<String> queries,
    String? pageTitle,
    String? description,
  }) {
    final cleaned = _clean(text);
    final headline = _headline(cleaned, pageTitle, description);
    final signal = '$headline ${_firstChars(cleaned, 400)}';
    final safeEntities = entities
        .map((entity) => entity.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((entity) => entity.length >= 3 && entity.length <= 60)
        .where((entity) => !entity.contains(RegExp(r'\d')))
        .take(6)
        .toList();
    final safeQueries = queries
        .map((query) => _trim(query, AppConstants.tavilyMaxQueryChars))
        .where((query) => query.isNotEmpty)
        .take(2)
        .toList();
    if (safeQueries.isEmpty) {
      return plan(text: text, pageTitle: pageTitle, description: description);
    }
    return _build(
      cleaned: cleaned,
      headline: headline,
      signal: signal,
      entities: safeEntities.isNotEmpty
          ? safeEntities
          : _entities(signal, headline),
      suppliedQueries: safeQueries,
    );
  }

  SearchPlan _build({
    required String cleaned,
    required String headline,
    required String signal,
    required List<String> entities,
    List<String>? suppliedQueries,
  }) {
    final intent = _intent(signal);
    final malay = FootballSearchLexicon.looksMalay(signal);
    final malaysian = malay || _hasMalaysianEntity(entities);

    final primaryQuery =
        suppliedQueries?.first ??
        _primaryQuery(
          headline: headline,
          cleaned: cleaned,
          entities: entities,
          intent: intent,
        );

    final queries = <PlannedQuery>[
      PlannedQuery(
        query: primaryQuery,
        options: _optionsFor(
          query: primaryQuery,
          intent: intent,
          malaysian: malaysian,
          language: malay ? 'ms' : null,
        ),
      ),
    ];

    if (suppliedQueries == null && malay) {
      final english = _englishQuery(primaryQuery);
      if (english.isNotEmpty &&
          english.toLowerCase() != primaryQuery.toLowerCase()) {
        queries.add(
          PlannedQuery(
            query: english,
            options: _optionsFor(
              query: english,
              intent: intent,
              malaysian: malaysian,
              language: 'en',
            ),
            isAlternative: true,
          ),
        );
      }
    }
    for (final extra in (suppliedQueries ?? const <String>[]).skip(1)) {
      if (queries.any((q) => q.query.toLowerCase() == extra.toLowerCase())) {
        continue;
      }
      queries.add(
        PlannedQuery(
          query: extra,
          options: _optionsFor(
            query: extra,
            intent: intent,
            malaysian: malaysian,
            language: 'en',
          ),
          isAlternative: true,
        ),
      );
    }

    final broad = _broadQuery(entities, intent, headline);
    if (broad.isNotEmpty &&
        !queries.any((q) => q.query.toLowerCase() == broad.toLowerCase())) {
      queries.add(
        PlannedQuery(
          query: broad,
          // Tavily has no `include_domains_mode: prefer`; restricting this
          // fallback query to known sports outlets is the supported way to
          // prefer trusted sources without inventing an API parameter.
          options:
              _optionsFor(
                query: broad,
                intent: intent,
                malaysian: malaysian,
                language: malay ? 'en' : null,
              ).copyWith(
                includeDomains: FootballSearchLexicon.preferredSearchDomains,
              ),
          isAlternative: true,
        ),
      );
    }

    return SearchPlan(
      headline: headline,
      entities: entities,
      intent: intent,
      queries: queries,
      keyEntity: _keyEntity(entities),
    );
  }

  String? _keyEntity(List<String> entities) {
    // A player's full name is far more discriminating than a club name, which
    // appears in almost every result of a team query.
    for (final entity in entities) {
      if (entity.trim().split(RegExp(r'\s+')).length > 1) return entity;
    }
    if (entities.isEmpty) return null;
    return entities.first;
  }

  /// Removes template headers before any query is built.
  ///
  /// Pasted posts from the app's own prompt templates often start with
  /// `TYPE: ... / DATE: ... / POST CONTENT: ...`. Treating those labels as the
  /// headline produced queries like "TYPE DATE Fri Nov POST CONTENT transfer
  /// news", which matches roundup pages instead of the named player.
  String _clean(String text) {
    final source = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'www\.\S+'), ' ')
        .replaceAll(RegExp(r'[#@]\w+'), ' ');

    final kept = <String>[];
    var sawTemplate = false;
    var sawContentMarker = false;
    for (final rawLine in source.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final labelled = RegExp(r'^([A-Za-z][A-Za-z ]{0,24})\s*:\s*(.*)$')
          .firstMatch(line);
      if (labelled != null) {
        final label = labelled
            .group(1)!
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (FootballSearchLexicon.templateLabels.contains(label)) {
          sawTemplate = true;
          final rest = labelled.group(2)!.trim();
          if (const {
            'post content',
            'content',
            'body',
            'headline',
            'title',
            'caption',
          }.contains(label)) {
            sawContentMarker = true;
            if (rest.isNotEmpty) kept.add(rest);
          }
          continue;
        }
      }
      kept.add(line);
    }
    var cleaned = kept.join('\n');

    // Same header, but pasted as one line with no colons.
    if (!sawContentMarker) {
      final inline = RegExp(
        r'\bPOST\s*CONTENT\b',
        caseSensitive: false,
      ).firstMatch(cleaned);
      if (inline != null) {
        sawTemplate = true;
        cleaned = cleaned.substring(inline.end);
      }
    }

    // Drop any leading template/date words left on the first line.
    var lines = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isNotEmpty) {
      final tokens = lines.first.split(RegExp(r'\s+'));
      var cut = 0;
      while (cut < tokens.length) {
        final word = tokens[cut].toLowerCase().replaceAll(
          RegExp(r'[^a-z]'),
          '',
        );
        if (!FootballSearchLexicon.templateLabels.contains(word) &&
            !FootballSearchLexicon.dateTokens.contains(word)) {
          break;
        }
        sawTemplate = true;
        cut++;
      }
      if (cut == tokens.length) {
        lines.removeAt(0);
      } else if (cut > 0) {
        lines[0] = tokens.sublist(cut).join(' ');
      }
    }
    cleaned = lines.join('\n');

    if (sawTemplate) {
      cleaned = cleaned.replaceAllMapped(RegExp(r'\b[A-Za-z]+\b'), (match) {
        final original = match.group(0)!;
        return FootballSearchLexicon.dateTokens.contains(original.toLowerCase())
            ? ' '
            : original;
      });
    }
    return cleaned
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\s*\n\s*'), '\n')
        .trim();
  }

  String _headline(String cleaned, String? pageTitle, String? description) {
    final title = (pageTitle ?? '').trim();
    if (title.isNotEmpty) return _trim(title, 160);

    // Prefer a short first line (a pasted headline), then a short first
    // sentence. A long opening sentence is a bad query on its own, so the
    // planner falls back to entities instead.
    for (final line in cleaned.split(RegExp(r'[\n•]'))) {
      final t = line.trim();
      if (t.length >= 12 && t.length <= 140) return t;
    }
    final firstSentence = cleaned.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length >= 12 && firstSentence.length <= 160) {
      return firstSentence;
    }
    final desc = (description ?? '').trim();
    if (desc.isNotEmpty) return _trim(desc, 160);
    return _trim(cleaned, 160);
  }

  List<String> _entities(String signal, String headline) {
    final found = <String>{...FootballSearchLexicon.findEntities(signal)};

    // Known clubs are safe even when they appear as a single capitalised word.
    final lower = signal.toLowerCase();
    for (final club in FootballSearchLexicon.knownClubs) {
      if (RegExp(
        r'(?<![a-z0-9])${RegExp.escape(club.toLowerCase())}(?![a-z0-9])',
      ).hasMatch(lower)) {
        found.add(club);
      }
    }

    // Capitalised name sequences. Scan the whole signal, not just the first
    // line: the player's name is often in the second paragraph while the first
    // line is a header or a generic lead. All-caps labels (TYPE, DATE) and
    // date tokens are rejected so "Fri Nov" can never become an entity.
    final matches = RegExp(
      r"\b([A-Z][a-zA-Z'.-]+(?:\s+[A-Z][a-zA-Z'.-]+){0,2})\b",
    ).allMatches(signal);
    for (final m in matches) {
      final phrase = m.group(1)!.trim();
      if (phrase.length < 4) continue;
      final words = phrase.split(RegExp(r'\s+'));
      final allCaps = words.every(
        (word) => word.length > 1 && word == word.toUpperCase(),
      );
      if (allCaps) continue;
      final lowerPhrase = phrase.toLowerCase();
      if (FootballSearchLexicon.stopwords.contains(lowerPhrase) ||
          FootballSearchLexicon.templateLabels.contains(lowerPhrase) ||
          words.any(
            (word) => FootballSearchLexicon.dateTokens.contains(
              word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''),
            ),
          )) {
        continue;
      }
      // A single capitalised word is only an entity if it is a known club or
      // a known alias; sentence-initial prose words are not names.
      if (words.length == 1 &&
          !FootballSearchLexicon.knownClubs.contains(phrase)) {
        continue;
      }
      found.add(phrase);
      if (found.length >= 6) break;
    }
    return found.toList();
  }

  String _intent(String signal) {
    final lower = signal.toLowerCase();
    for (final intent in FootballSearchLexicon.intentPriority) {
      final keywords = FootballSearchLexicon.intentKeywords[intent] ?? const [];
      for (final keyword in keywords) {
        if (RegExp('(?<![a-z0-9])${RegExp.escape(keyword)}(?![a-z0-9])')
            .hasMatch(lower)) {
          return intent;
        }
      }
    }
    return 'general';
  }

  String _primaryQuery({
    required String headline,
    required String cleaned,
    required List<String> entities,
    required String intent,
  }) {
    // A pasted headline is already a good query. Add the canonical entity
    // only when the headline is short enough that the entity adds signal.
    if (headline.isNotEmpty && headline.length <= 120) {
      final withEntity = _ensureEntity(headline, entities);
      return _trim(withEntity, AppConstants.tavilyMaxQueryChars);
    }
    if (entities.isNotEmpty) {
      final keyword = _intentKeyword(intent);
      return _trim(
        [...entities, ?keyword].join(' '),
        AppConstants.tavilyMaxQueryChars,
      );
    }
    final keyword = _intentKeyword(intent);
    final base = _trim(cleaned, 140);
    return _trim(
      keyword == null ? base : '$base $keyword',
      AppConstants.tavilyMaxQueryChars,
    );
  }

  String _ensureEntity(String headline, List<String> entities) {
    final lower = headline.toLowerCase();
    for (final entity in entities) {
      if (lower.contains(entity.toLowerCase())) return headline;
    }
    // If the headline is very short ("Kalah 2-1"), prepend the first entity.
    if (headline.split(' ').length <= 4 && entities.isNotEmpty) {
      return '${entities.first} $headline';
    }
    return headline;
  }

  String _broadQuery(List<String> entities, String intent, String headline) {
    final keyword = _intentKeyword(intent);
    if (entities.isNotEmpty) {
      return _trim(
        [...entities.take(3), ?keyword].join(' '),
        AppConstants.tavilyMaxQueryChars,
      );
    }
    final tokens = headline
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .where((t) => !FootballSearchLexicon.stopwords.contains(t))
        .take(8)
        .toList();
    if (tokens.isEmpty) return '';
    return _trim(
      [...tokens, ?keyword].join(' '),
      AppConstants.tavilyMaxQueryChars,
    );
  }

  String _englishQuery(String query) {
    final words = query.split(RegExp(r'\s+'));
    final mapped = <String>[];
    for (final word in words) {
      final key = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final english = FootballSearchLexicon.malayToEnglish[key];
      mapped.add(english ?? word);
    }
    // Canonicalise any aliases that survived translation.
    final translated = mapped.join(' ');
    final entities = FootballSearchLexicon.findEntities(query);
    if (entities.isEmpty) {
      return _trim(translated, AppConstants.tavilyMaxQueryChars);
    }
    return _trim(
      '${entities.take(2).join(' ')} $translated',
      AppConstants.tavilyMaxQueryChars,
    );
  }

  String? _intentKeyword(String intent) => switch (intent) {
    'result' => 'match report result',
    'injury' => 'injury update',
    'lineup' => 'lineup',
    'transfer' => 'transfer news',
    'stats' => 'stats season record',
    'preview' => 'match preview',
    _ => null,
  };

  SearchOptions _optionsFor({
    required String query,
    required String intent,
    required bool malaysian,
    String? language,
  }) {
    final base = SearchOptions(
      query: query,
      maxResults: AppConstants.tavilyMaxSources,
      chunksPerSource: 2,
      includeAnswer: false,
      searchDepth: 'basic',
      excludeDomains: FootballSearchLexicon.excludedDomains.toList(),
      language: language,
    );

    return switch (intent) {
      'result' => base.copyWith(
        topic: 'general',
        timeRange: 'day',
        country: malaysian ? 'malaysia' : null,
      ),
      'injury' ||
      'lineup' ||
      'transfer' => base.copyWith(topic: 'news', timeRange: 'week'),
      'preview' => base.copyWith(topic: 'news', timeRange: 'week'),
      'stats' => base.copyWith(topic: 'general'),
      _ => base.copyWith(topic: 'news', timeRange: 'month'),
    };
  }

  bool _hasMalaysianEntity(List<String> entities) {
    const markers = [
      'johor',
      'malaysia',
      'selangor',
      'sabah',
      'sarawak',
      'terengganu',
      'kedah',
      'penang',
      'perak',
      'pahang',
      'kelantan',
      'kuala lumpur',
      'negeri sembilan',
      'harimau',
    ];
    final lower = entities.join(' ').toLowerCase();
    return markers.any(lower.contains);
  }

  String _firstChars(String text, int n) =>
      text.length <= n ? text : text.substring(0, n);

  String _trim(String text, int max) {
    final cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s\-–—:;,.]+'), '')
        .replaceAll(RegExp(r'[\s\-–—:;,]+$'), '')
        .trim();
    if (cleaned.length <= max) return cleaned;
    final cut = cleaned.substring(0, max);
    final lastSpace = cut.lastIndexOf(' ');
    return (lastSpace > max * 0.6 ? cut.substring(0, lastSpace) : cut).trim();
  }
}
