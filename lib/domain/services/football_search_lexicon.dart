/// Football-domain vocabulary used to turn pasted text into a focused search
/// query and to judge whether a result is actually about the same story.
///
/// The app curates Malaysian football in Bahasa Malaysia, while most detailed
/// stats/fixtures are indexed in English. This lexicon bridges both directions
/// and gives the relevance guard a small, deterministic signal set.
class FootballSearchLexicon {
  const FootballSearchLexicon._();

  /// Canonical English name for common Malay/abbreviated entities.
  /// Matching is case-insensitive on word boundaries.
  static const Map<String, String> entityAliases = {
    'jdt': 'Johor Darul Ta\'zim',
    'johor darul ta\'zim': 'Johor Darul Ta\'zim',
    'johor dt': 'Johor Darul Ta\'zim',
    'harimau malaya': 'Malaysia national football team',
    'pasukan kebangsaan malaysia': 'Malaysia national football team',
    'malaysia national team': 'Malaysia national football team',
    'liga super': 'Malaysia Super League',
    'liga super malaysia': 'Malaysia Super League',
    'piala fa': 'Malaysia FA Cup',
    'piala malaysia': 'Malaysia Cup',
    'piala aff': 'ASEAN Championship',
    'aff cup': 'ASEAN Championship',
    'piala asean': 'ASEAN Championship',
    'selangor fc': 'Selangor FC',
    'kuala lumpur city': 'Kuala Lumpur City FC',
    'sabah fc': 'Sabah FC',
    'terengganu fc': 'Terengganu FC',
    'kedah darul aman': 'Kedah Darul Aman FC',
    'pulau pinang': 'Penang FC',
    'perak fc': 'Perak FC',
    'pahang fc': 'Pahang FC',
    'negeri sembilan': 'Negeri Sembilan FC',
    'kelantan fc': 'Kelantan FC',
    'kuching city': 'Kuching City FC',
    'manchester united': 'Manchester United',
    'man united': 'Manchester United',
    'man city': 'Manchester City',
    'real madrid': 'Real Madrid',
    'barcelona': 'Barcelona',
    'barca': 'Barcelona',
    'bayern munich': 'Bayern Munich',
    'bayern': 'Bayern Munich',
    'psg': 'Paris Saint-Germain',
    'paris saint-germain': 'Paris Saint-Germain',
    'atletico madrid': 'Atletico Madrid',
    'tottenham': 'Tottenham Hotspur',
    'spurs': 'Tottenham Hotspur',
  };

  /// Clubs that are safe to put into a search query even when they appear as
  /// a single capitalised word. Kept small and explicit: an arbitrary capital
  /// at the start of a sentence is not enough to become an entity.
  static const Set<String> knownClubs = {
    'Arsenal',
    'Chelsea',
    'Liverpool',
    'Manchester United',
    'Manchester City',
    'Tottenham Hotspur',
    'Newcastle United',
    'Aston Villa',
    'Brighton',
    'West Ham',
    'Barcelona',
    'Real Madrid',
    'Bayern Munich',
    'Paris Saint-Germain',
    'Inter Milan',
    'AC Milan',
    'Juventus',
    'Johor Darul Ta\'zim',
    'Selangor FC',
    'Kuala Lumpur City FC',
    'Sabah FC',
    'Terengganu FC',
    'Harimau Malaya',
  };

  /// Domains used for the trusted-source fallback query. Tavily has no
  /// "prefer domains" mode; restricting this one query to known outlets is the
  /// closest supported equivalent.
  static const List<String> preferredSearchDomains = [
    'bbc.com',
    'skysports.com',
    'espn.com',
    'reuters.com',
    'theathletic.com',
    'goal.com',
    'stadiumastro.com',
    'bernama.com',
    'thestar.com.my',
    'malaymail.com',
  ];

  /// Labels pasted by the app's own prompt templates. A line beginning with
  /// one of these is metadata, not article text.
  static const Set<String> templateLabels = {
    'type',
    'date',
    'time',
    'post content',
    'post',
    'content',
    'body',
    'headline',
    'title',
    'source',
    'url',
    'category',
    'topic',
    'author',
    'caption',
  };

  /// Standalone day/month tokens. These are date noise, never football
  /// entities, and must not survive into a query.
  static const Set<String> dateTokens = {
    'mon',
    'monday',
    'tue',
    'tues',
    'tuesday',
    'wed',
    'weds',
    'wednesday',
    'thu',
    'thur',
    'thurs',
    'thursday',
    'fri',
    'friday',
    'sat',
    'saturday',
    'sun',
    'sunday',
    'jan',
    'january',
    'feb',
    'february',
    'mar',
    'march',
    'apr',
    'april',
    'may',
    'jun',
    'june',
    'jul',
    'july',
    'aug',
    'august',
    'sep',
    'sept',
    'september',
    'oct',
    'october',
    'nov',
    'november',
    'dec',
    'december',
  };

  /// Malay → English football terms. Used to build an English alias query.
  static const Map<String, String> malayToEnglish = {
    'kalah': 'lost',
    'kekalahan': 'defeat',
    'menang': 'win',
    'kemenangan': 'victory',
    'seri': 'draw',
    'keputusan': 'result',
    'perlawanan': 'match',
    'pertandingan': 'match',
    'pemain': 'player',
    'pasukan': 'team',
    'jurulatih': 'coach',
    'pengurus': 'manager',
    'cedera': 'injury',
    'kecederaan': 'injury',
    'kontrak': 'contract',
    'perjanjian': 'contract',
    'pinjaman': 'loan',
    'perpindahan': 'transfer',
    'piala': 'cup',
    'liga': 'league',
    'gol': 'goal',
    'jaringan': 'goal',
    'assist': 'assist',
    'statistik': 'stats',
    'rekod': 'record',
    'sejarah': 'history',
    'dijangka': 'expected',
    'bakal': 'set to',
    'akan': 'will',
    'bertemu': 'face',
    'menentang': 'against',
    'tewas': 'lost',
    'mata': 'points',
    'kedudukan': 'standings',
    'jadual': 'fixtures',
    'penjaring': 'scorer',
    'penjaring terbanyak': 'top scorer',
    'kapten': 'captain',
    'penalti': 'penalty',
    'kad merah': 'red card',
    'kad kuning': 'yellow card',
    'separuh masa': 'half time',
    'masa penuh': 'full time',
  };

  /// Words that carry no retrieval signal. Kept short: over-filtering hurts
  /// short queries more than it helps long ones.
  static const Set<String> stopwords = {
    'the',
    'a',
    'an',
    'and',
    'or',
    'but',
    'if',
    'of',
    'to',
    'in',
    'on',
    'at',
    'for',
    'from',
    'by',
    'with',
    'as',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'this',
    'that',
    'these',
    'those',
    'it',
    'its',
    'he',
    'she',
    'they',
    'we',
    'you',
    'his',
    'her',
    'their',
    'our',
    'has',
    'have',
    'had',
    'will',
    'would',
    'can',
    'could',
    'should',
    'after',
    'before',
    'during',
    'about',
    'into',
    'over',
    'under',
    'more',
    'most',
    'than',
    'then',
    'also',
    'just',
    'very',
    'dan',
    'yang',
    'dengan',
    'untuk',
    'dari',
    'dalam',
    'pada',
    'telah',
    'akan',
    'tidak',
    'ini',
    'itu',
    'satu',
    'atau',
    'juga',
    'sudah',
    'masih',
    'boleh',
    'kata',
    'kepada',
    'oleh',
    'sebagai',
    'bagi',
    'antara',
    'selepas',
    'sebelum',
    'semasa',
    'lebih',
    'paling',
    'hanya',
    'serta',
    'tetapi',
    'kerana',
    'ialah',
  };

  /// Intent keyword groups. First match wins in [intentPriority].
  static const List<String> intentPriority = [
    'result',
    'injury',
    'lineup',
    'transfer',
    'stats',
    'preview',
  ];

  static const Map<String, List<String>> intentKeywords = {
    'result': [
      'result',
      'keputusan',
      'score',
      'scores',
      'skor',
      'full-time',
      'full time',
      'masa penuh',
      'final score',
      'won',
      'lost',
      'draw',
      'menang',
      'kalah',
      'seri',
      'tewas',
      'beat',
      'defeated',
      'vs',
      'versus',
      'highlights',
    ],
    'injury': [
      'injury',
      'injured',
      'cedera',
      'kecederaan',
      'fitness',
      'out for',
      'ruled out',
      'sidelined',
      'absen',
    ],
    'lineup': [
      'lineup',
      'line-up',
      'starting xi',
      'starting eleven',
      'kesebelasan',
      'susunan pemain',
      'formation',
      'formasi',
    ],
    'transfer': [
      'transfer',
      'signing',
      'sign',
      'signed',
      'pinjaman',
      'loan',
      'kontrak',
      'contract',
      'perpindahan',
      'perjanjian',
      'fee',
      'bid',
      'move',
    ],
    'stats': [
      'stats',
      'statistics',
      'statistik',
      'xg',
      'expected goals',
      'possession',
      'passes',
      'shots',
      'record',
      'rekod',
      'milestone',
      'goals',
      'assists',
      'jaringan',
      'penjaring',
    ],
    'preview': [
      'preview',
      'pratonton',
      'ahead of',
      'will face',
      'bakal bertemu',
      'menentang',
      'fixture',
      'jadual',
    ],
  };

  /// Trusted outlets get a ranking bonus and a noise penalty exemption.
  /// Keys are registrable domains (no `www.`).
  static const Map<String, String> trustedDomains = {
    'bbc.com': 'BBC Sport',
    'bbc.co.uk': 'BBC Sport',
    'espn.com': 'ESPN',
    'espn.com.my': 'ESPN Malaysia',
    'reuters.com': 'Reuters',
    'skysports.com': 'Sky Sports',
    'theathletic.com': 'The Athletic',
    'goal.com': 'Goal',
    'transfermarkt.com': 'Transfermarkt',
    'flashsukan.com.my': 'Flash Sukan',
    'stadiumastro.com': 'Stadium Astro',
    'astroarena.com.my': 'Astro Arena',
    'bernama.com': 'Bernama',
    'bharian.com.my': 'Berita Harian',
    'hmetro.com.my': 'Harian Metro',
    'nst.com.my': 'New Straits Times',
    'thestar.com.my': 'The Star',
    'malaymail.com': 'Malay Mail',
    'vocketfc.com': 'Vocket FC',
    'semuanyabola.com': 'Semuanya Bola',
    'utusan.com.my': 'Utusan Malaysia',
    'sinarharian.com.my': 'Sinar Harian',
    'kosmo.com.my': 'Kosmo!',
    'mstar.com.my': 'mStar',
    'fifa.com': 'FIFA',
    'uefa.com': 'UEFA',
    'afc.com': 'AFC',
    'the-afc.com': 'AFC',
  };

  /// Domains that never add factual value to a curated post.
  static const Set<String> excludedDomains = {
    'facebook.com',
    'instagram.com',
    'x.com',
    'twitter.com',
    't.co',
    'tiktok.com',
    'youtube.com',
    'reddit.com',
    'pinterest.com',
    'quora.com',
    'bet365.com',
    '1xbet.com',
    'sbobet.com',
    'dafabet.com',
    'pinnacle.com',
    'oddschecker.com',
    'bettingexpert.com',
    'soccerway.com',
    'flashscore.com',
    'livescore.com',
    'sofascore.com',
  };

  /// Titles that are almost always betting/streaming spam.
  static const List<String> noiseTitleMarkers = [
    'betting odds',
    'odds',
    'free bet',
    'live stream',
    'streaming',
    'prediction',
    'ramalan',
    'tips',
    'judi',
    'ticket',
    'tiket',
    'watch live',
    'download app',
  ];

  static bool looksMalay(String text) {
    final lower = text.toLowerCase();
    var hits = 0;
    for (final word in const [
      'dan',
      'yang',
      'dengan',
      'untuk',
      'dari',
      'dalam',
      'pada',
      'telah',
      'akan',
      'tidak',
      'ini',
      'itu',
      'kalah',
      'menang',
      'perlawanan',
      'pemain',
      'pasukan',
      'gol',
      'liga',
      'piala',
      'cedera',
      'jurulatih',
      'kontrak',
    ]) {
      if (RegExp('\\b$word\\b').hasMatch(lower)) hits++;
      if (hits >= 3) return true;
    }
    return false;
  }

  /// Canonicalises a known alias or returns null.
  static String? canonicalEntity(String text) {
    final lower = text.toLowerCase().trim();
    for (final entry in entityAliases.entries) {
      if (lower == entry.key) return entry.value;
    }
    return null;
  }

  /// Maps known aliases found inside [text] to canonical names.
  static List<String> findEntities(String text) {
    final lower = text.toLowerCase();
    final found = <String>{};
    for (final entry in entityAliases.entries) {
      final pattern = RegExp(
        '(?<![a-z0-9])${RegExp.escape(entry.key)}(?![a-z0-9])',
      );
      if (pattern.hasMatch(lower)) found.add(entry.value);
    }
    return found.toList();
  }

  static String domainOf(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static String outletForDomain(String url) {
    final domain = domainOf(url);
    if (domain.isEmpty) return '';
    final direct = trustedDomains[domain];
    if (direct != null) return direct;
    // Match parent domains (sport.example.com.my → example.com.my).
    for (final entry in trustedDomains.entries) {
      if (domain.endsWith('.${entry.key}')) return entry.value;
    }
    return '';
  }

  static bool isTrustedDomain(String url) => outletForDomain(url).isNotEmpty;

  static bool isExcludedDomain(String url) {
    final domain = domainOf(url);
    if (domain.isEmpty) return false;
    if (excludedDomains.contains(domain)) return true;
    for (final excluded in excludedDomains) {
      if (domain.endsWith('.$excluded')) return true;
    }
    return false;
  }
}
