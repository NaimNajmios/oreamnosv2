import 'package:flutter/material.dart';

enum CardTemplate {
  playerSpotlight('Player Spotlight', 'Player performance highlight', [
    Color(0xFF1A237E),
    Color(0xFF283593),
  ]),
  headlineQuote('Headline Quote', 'Key quote or headline', [
    Color(0xFF004D40),
    Color(0xFF00695C),
  ]),
  topStats('Top 3 Statistics', 'Statistical comparison', [
    Color(0xFF4A148C),
    Color(0xFF6A1B9A),
  ]),
  transferNews('Transfer News', 'Transfers & rumors', [
    Color(0xFFB71C1C),
    Color(0xFFD32F2F),
  ]),
  breakingNews('Breaking News', 'Urgent / breaking news', [
    Color(0xFF880E4F),
    Color(0xFFE11D48),
  ]),
  matchPreview('Match Preview', 'Upcoming fixture', [
    Color(0xFF0D47A1),
    Color(0xFF1976D2),
  ]),
  detailedScoreboard('Detailed Scoreboard', 'Full scoreboard stats', [
    Color(0xFF1B5E20),
    Color(0xFF2E7D32),
  ]),
  onThisDay('On This Day', 'Anniversary moment', [
    Color(0xFF4E342E),
    Color(0xFF6D4C41),
  ]),
  startingXI('Starting XI', 'Team lineup display', [
    Color(0xFF263238),
    Color(0xFF37474F),
  ]),
  matchStatsComparison('Match Stats Comparison', 'Side-by-side stats', [
    Color(0xFF01579B),
    Color(0xFF0288D1),
  ]),
  socialPost('Social Post', 'Minimalist social post', [
    Color(0xFF212121),
    Color(0xFF424242),
  ]),
  rivalry('Head-to-Head', 'Rivalry comparison', [
    Color(0xFF311B92),
    Color(0xFF4527A0),
  ]),
  tableStandings('League Standings', 'League table', [
    Color(0xFF006064),
    Color(0xFF00838F),
  ]),
  injuryReport('Injury Report', 'Injury update', [
    Color(0xFFBF360C),
    Color(0xFFE64A19),
  ]),
  contractExpiry('Expiring Contracts', 'Contract expiry list', [
    Color(0xFF33691E),
    Color(0xFF558B2F),
  ]),
  awardNominee('Award Nominees', 'Award ceremony nominees', [
    Color(0xFFF57F17),
    Color(0xFFFF8F00),
  ]);

  const CardTemplate(this.displayName, this.description, this.previewGradient);

  final String displayName;
  final String description;
  final List<Color> previewGradient;

  static const List<CardTemplate> all = [
    playerSpotlight,
    headlineQuote,
    topStats,
    transferNews,
    breakingNews,
    matchPreview,
    detailedScoreboard,
    onThisDay,
    startingXI,
    matchStatsComparison,
    socialPost,
    rivalry,
    tableStandings,
    injuryReport,
    contractExpiry,
    awardNominee,
  ];

  static const String fallbackNA = 'N/A';

  // Template intent values used in CardPromptManager (CRITICAL RULE 4)
  String get templateIntent {
    switch (this) {
      case playerSpotlight:
        return 'player_spotlight';
      case headlineQuote:
        return 'headline_quote';
      case topStats:
        return 'top_stats';
      case transferNews:
        return 'transfer_news';
      case breakingNews:
        return 'breaking_news';
      case matchPreview:
        return 'match_preview';
      case detailedScoreboard:
        return 'detailed_scoreboard';
      case onThisDay:
        return 'on_this_day';
      case startingXI:
        return 'starting_xi';
      case matchStatsComparison:
        return 'match_stats_comparison';
      case socialPost:
        return 'social_post';
      case rivalry:
        return 'rivalry';
      case tableStandings:
        return 'table_standings';
      case injuryReport:
        return 'injury_report';
      case contractExpiry:
        return 'contract_expiry';
      case awardNominee:
        return 'award_nominee';
    }
  }

  static CardTemplate fromIntent(String? intent) {
    if (intent == null) return socialPost;
    for (final t in all) {
      if (t.templateIntent == intent) return t;
    }
    return socialPost;
  }

  static CardTemplate fromLegacy(String name) {
    switch (name) {
      case 'playerSpotlight':
        return playerSpotlight;
      case 'headlineQuote':
        return headlineQuote;
      case 'topStats':
        return topStats;
      case 'transferNews':
        return transferNews;
      case 'breakingNews':
        return breakingNews;
      case 'matchPreview':
        return matchPreview;
      case 'detailedScoreboard':
        return detailedScoreboard;
      case 'onThisDay':
        return onThisDay;
      case 'startingXI':
        return startingXI;
      case 'matchStatsComparison':
        return matchStatsComparison;
      case 'socialPost':
        return socialPost;
      case 'rivalry':
        return rivalry;
      case 'tableStandings':
        return tableStandings;
      case 'injuryReport':
        return injuryReport;
      case 'contractExpiry':
        return contractExpiry;
      case 'awardNominee':
        return awardNominee;
      default:
        return socialPost;
    }
  }
}
