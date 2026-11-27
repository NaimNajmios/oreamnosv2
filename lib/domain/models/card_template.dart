import 'package:flutter/material.dart';

enum CardTemplate {
  playerSpotlight('Player Spotlight', 'Player performance highlight', [
    Color(0xFF0B0B0F),
    Color(0xFF1B2A6B),
  ]),
  headlineQuote('Headline Quote', 'Key quote or headline', [
    Color(0xFF0B0B0F),
    Color(0xFF0E4F45),
  ]),
  topStats('Top 3 Statistics', 'Statistical comparison', [
    Color(0xFF0B0B0F),
    Color(0xFF3B1B6B),
  ]),
  transferNews('Transfer News', 'Transfers & rumors', [
    Color(0xFF0B0B0F),
    Color(0xFF6B1B1B),
  ]),
  breakingNews('Breaking News', 'Urgent / breaking news', [
    Color(0xFF0B0B0F),
    Color(0xFF5C1230),
  ]),
  matchPreview('Match Preview', 'Upcoming fixture', [
    Color(0xFF0B0B0F),
    Color(0xFF123A6B),
  ]),
  detailedScoreboard('Detailed Scoreboard', 'Full scoreboard stats', [
    Color(0xFF0B0B0F),
    Color(0xFF14491E),
  ]),
  onThisDay('On This Day', 'Anniversary moment', [
    Color(0xFF0B0B0F),
    Color(0xFF3E2A22),
  ]),
  startingXI('Starting XI', 'Team lineup display', [
    Color(0xFF0B0B0F),
    Color(0xFF1F2B30),
  ]),
  matchStatsComparison('Match Stats Comparison', 'Side-by-side stats', [
    Color(0xFF0B0B0F),
    Color(0xFF0E3D5C),
  ]),
  socialPost('Social Post', 'Minimalist social post', [
    Color(0xFF0B0B0F),
    Color(0xFF1C1C1C),
  ]),
  rivalry('Head-to-Head', 'Rivalry comparison', [
    Color(0xFF0B0B0F),
    Color(0xFF281B6B),
  ]),
  tableStandings('League Standings', 'League table', [
    Color(0xFF0B0B0F),
    Color(0xFF0A3A42),
  ]),
  injuryReport('Injury Report', 'Injury update', [
    Color(0xFF0B0B0F),
    Color(0xFF6B2410),
  ]),
  contractExpiry('Expiring Contracts', 'Contract expiry list', [
    Color(0xFF0B0B0F),
    Color(0xFF2F4A12),
  ]),
  awardNominee('Award Nominees', 'Award ceremony nominees', [
    Color(0xFF0B0B0F),
    Color(0xFF6B5208),
  ]),
  freeform('Freeform', 'Draggable text elements', [
    Color(0xFF0B0B0F),
    Color(0xFF1F2B30),
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
    freeform,
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
      case freeform:
        return 'freeform';
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
