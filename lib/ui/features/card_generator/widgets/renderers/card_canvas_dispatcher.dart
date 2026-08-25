import 'package:flutter/material.dart';
import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import 'player_spotlight_canvas.dart';
import 'headline_quote_canvas.dart';
import 'top_stats_canvas.dart';
import 'transfer_news_canvas.dart';
import 'breaking_news_canvas.dart';
import 'match_preview_canvas.dart';
import 'detailed_scoreboard_canvas.dart';
import 'on_this_day_canvas.dart';
import 'starting_xi_canvas.dart';
import 'match_stats_comparison_canvas.dart';
import 'social_post_canvas.dart';
import 'rivalry_canvas.dart';
import 'table_standings_canvas.dart';
import 'injury_report_canvas.dart';
import 'contract_expiry_canvas.dart';
import 'award_nominee_canvas.dart';

class CardCanvasDispatcher extends StatelessWidget {
  const CardCanvasDispatcher({super.key, required this.cardData, required this.config});
  final CardData cardData;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    return cardData.map(
      playerSpotlight: (d) => PlayerSpotlightCanvas(data: d, config: config),
      headlineQuote: (d) => HeadlineQuoteCanvas(data: d, config: config),
      topStats: (d) => TopStatsCanvas(data: d, config: config),
      transferNews: (d) => TransferNewsCanvas(data: d, config: config),
      breakingNews: (d) => BreakingNewsCanvas(data: d, config: config),
      matchPreview: (d) => MatchPreviewCanvas(data: d, config: config),
      detailedScoreboard: (d) => DetailedScoreboardCanvas(data: d, config: config),
      onThisDay: (d) => OnThisDayCanvas(data: d, config: config),
      startingXI: (d) => StartingXICanvas(data: d, config: config),
      matchStatsComparison: (d) => MatchStatsComparisonCanvas(data: d, config: config),
      socialPost: (d) => SocialPostCanvas(data: d, config: config),
      rivalry: (d) => RivalryCanvas(data: d, config: config),
      tableStandings: (d) => TableStandingsCanvas(data: d, config: config),
      injuryReport: (d) => InjuryReportCanvas(data: d, config: config),
      contractExpiry: (d) => ContractExpiryCanvas(data: d, config: config),
      awardNominee: (d) => AwardNomineeCanvas(data: d, config: config),
      sparse: (d) => SocialPostCanvas(data: CardData.socialPost(content: d.headline, metrics: d.subtext, handle: d.microStat ?? 'N/A') as SocialPost, config: config),
    );
  }
}
