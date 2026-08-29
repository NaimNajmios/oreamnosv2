import 'package:freezed_annotation/freezed_annotation.dart';

import 'card_template.dart';

part 'card_data.freezed.dart';
part 'card_data.g.dart';

// Helper nested types
@freezed
abstract class StatItem with _$StatItem {
  const factory StatItem({
    required String label,
    required String value,
    @Default('N/A') String context,
  }) = _StatItem;
  factory StatItem.fromJson(Map<String, dynamic> json) =>
      _$StatItemFromJson(json);
}

@freezed
abstract class ComparisonStat with _$ComparisonStat {
  const factory ComparisonStat({
    required String label,
    required String homeValue,
    required String awayValue,
  }) = _ComparisonStat;
  factory ComparisonStat.fromJson(Map<String, dynamic> json) =>
      _$ComparisonStatFromJson(json);
}

@freezed
abstract class LineupPlayer with _$LineupPlayer {
  const factory LineupPlayer({required String number, required String name}) =
      _LineupPlayer;
  factory LineupPlayer.fromJson(Map<String, dynamic> json) =>
      _$LineupPlayerFromJson(json);
}

@freezed
abstract class TableRow with _$TableRow {
  const factory TableRow({
    required int position,
    required String teamName,
    required int played,
    required int won,
    required int drawn,
    required int lost,
    required int points,
    @Default('N/A') String form,
  }) = _TableRow;
  factory TableRow.fromJson(Map<String, dynamic> json) =>
      _$TableRowFromJson(json);
}

@freezed
abstract class InjuryItem with _$InjuryItem {
  const factory InjuryItem({
    required String playerName,
    required String injury,
    required String status,
    @Default('N/A') String position,
    @Default('N/A') String recoveryPercentage,
    @Default(false) bool isLongTerm,
    @Default(false) bool surgeryRequired,
  }) = _InjuryItem;
  factory InjuryItem.fromJson(Map<String, dynamic> json) =>
      _$InjuryItemFromJson(json);
}

@freezed
abstract class ContractPlayer with _$ContractPlayer {
  const factory ContractPlayer({
    required String playerName,
    required String position,
    required String expiresIn,
    @Default('N/A') String marketValue,
    @Default('N/A') String status,
    @Default('N/A') String wage,
    @Default('N/A') String askingPrice,
    @Default('N/A') String interestLevel,
    @Default('N/A') String negotiationProgress,
    @Default('N/A') String previousClub,
  }) = _ContractPlayer;
  factory ContractPlayer.fromJson(Map<String, dynamic> json) =>
      _$ContractPlayerFromJson(json);
}

@freezed
abstract class NomineeItem with _$NomineeItem {
  const factory NomineeItem({
    required String playerName,
    required String club,
    required String achievement,
    @Default('N/A') String odds,
    @Default(false) bool isFavorite,
    @Default(false) bool previousWinner,
    @Default('N/A') String votes,
  }) = _NomineeItem;
  factory NomineeItem.fromJson(Map<String, dynamic> json) =>
      _$NomineeItemFromJson(json);
}

@freezed
sealed class CardData with _$CardData {
  const CardData._();

  const factory CardData.playerSpotlight({
    required String playerName,
    @Default('N/A') String club,
    @Default('N/A') String position,
    @Default(0.0) double rating,
    @Default(0) int goals,
    @Default(0) int assists,
    @Default(0) int minutesPlayed,
    @Default('N/A') String keyAction,
    @Default('N/A') String keyQuote,
    @Default('N/A') String nationality,
    @Default(0) int appearances,
    @Default(0) int cleanSheets,
    @Default(0) int passes,
    @Default(0) int tackles,
    CardTemplate? suggestedTemplate,
  }) = PlayerSpotlight;

  const factory CardData.headlineQuote({
    required String headline,
    required String subtext,
    @Default('N/A') String quoteAuthor,
    @Default('N/A') String authorTitle,
    @Default('N/A') String category,
    @Default('N/A') String relatedTeams,
    CardTemplate? suggestedTemplate,
  }) = HeadlineQuote;

  const factory CardData.topStats({
    @Default('N/A') String matchContext,
    @Default([]) List<StatItem> stats,
    CardTemplate? suggestedTemplate,
  }) = TopStats;

  const factory CardData.transferNews({
    required String playerName,
    @Default('N/A') String action,
    @Default('N/A') String fromTeam,
    @Default('N/A') String toTeam,
    @Default('N/A') String fee,
    @Default('N/A') String contractLength,
    @Default('N/A') String transferType,
    @Default('N/A') String quote,
    @Default('N/A') String feeCategory,
    @Default(false) bool medicalCompleted,
    @Default(false) bool workPermit,
    @Default('N/A') String agentName,
    CardTemplate? suggestedTemplate,
  }) = TransferNews;

  const factory CardData.breakingNews({
    @Default('🚨 BREAKING') String label,
    required String headline,
    @Default('N/A') String subtext,
    @Default(3) int impactRating,
    @Default('N/A') String relatedTeams,
    CardTemplate? suggestedTemplate,
  }) = BreakingNews;

  const factory CardData.matchPreview({
    @Default('N/A') String competition,
    required String homeTeam,
    required String awayTeam,
    @Default('N/A') String homeForm,
    @Default('N/A') String awayForm,
    @Default('N/A') String matchTime,
    @Default('N/A') String stadium,
    @Default('N/A') String referee,
    @Default('N/A') String tvChannel,
    @Default('N/A') String kickoffTime,
    @Default('N/A') String weather,
    @Default('N/A') String capacity,
    CardTemplate? suggestedTemplate,
  }) = MatchPreview;

  const factory CardData.detailedScoreboard({
    required String homeTeam,
    required String awayTeam,
    @Default(0) int homeScore,
    @Default(0) int awayScore,
    @Default('N/A') String homeScorers,
    @Default('N/A') String awayScorers,
    @Default('N/A') String possession,
    @Default('N/A') String shotsOnTarget,
    @Default('N/A') String competition,
    @Default('N/A') String matchStatus,
    @Default('N/A') String corners,
    @Default('N/A') String fouls,
    @Default('N/A') String yellowCards,
    @Default('N/A') String redCards,
    @Default('N/A') String attendance,
    @Default('N/A') String referee,
    @Default('N/A') String penaltyShootout,
    @Default('N/A') String assistProviders,
    CardTemplate? suggestedTemplate,
  }) = DetailedScoreboard;

  const factory CardData.onThisDay({
    @Default('N/A') String dateLabel,
    @Default(0) int yearsAgo,
    @Default('N/A') String competition,
    @Default('N/A') String headline,
    @Default([]) List<StatItem> keyStats,
    @Default('N/A') String venue,
    @Default('N/A') String attendance,
    @Default('N/A') String result,
    @Default('N/A') String significance,
    CardTemplate? suggestedTemplate,
  }) = OnThisDay;

  const factory CardData.startingXI({
    @Default('N/A') String teamName,
    @Default('N/A') String formation,
    @Default([]) List<LineupPlayer> starters,
    @Default([]) List<LineupPlayer> subs,
    @Default('N/A') String manager,
    @Default('N/A') String averageAge,
    @Default('N/A') String keyAbsences,
    @Default('N/A') String captain,
    @Default('N/A') String viceCaptain,
    @Default('N/A') String tactics,
    @Default('N/A') String injuredPlayers,
    @Default('N/A') String suspendedPlayers,
    CardTemplate? suggestedTemplate,
  }) = StartingXI;

  const factory CardData.matchStatsComparison({
    @Default('N/A') String homeTeam,
    @Default('N/A') String awayTeam,
    @Default([]) List<ComparisonStat> stats,
    CardTemplate? suggestedTemplate,
  }) = MatchStatsComparison;

  const factory CardData.socialPost({
    @Default('N/A') String handle,
    @Default('N/A') String name,
    @Default('N/A') String content,
    @Default('N/A') String timestamp,
    @Default('N/A') String metrics,
    @Default(false) bool verified,
    @Default('N/A') String followers,
    @Default('N/A') String shares,
    @Default('N/A') String bookmarks,
    @Default('N/A') String mediaType,
    @Default(false) bool isEdited,
    CardTemplate? suggestedTemplate,
  }) = SocialPost;

  const factory CardData.rivalry({
    @Default('N/A') String player1Name,
    @Default('N/A') String player2Name,
    @Default('N/A') String matchContext,
    @Default([]) List<StatItem> player1Stats,
    @Default([]) List<StatItem> player2Stats,
    @Default('N/A') String headToHead,
    @Default('N/A') String verdict,
    @Default('N/A') String compareType,
    @Default('N/A') String totalMatches,
    @Default('N/A') String draws,
    @Default('N/A') String player1Trophies,
    @Default('N/A') String player2Trophies,
    @Default('N/A') String predictionConfidence,
    CardTemplate? suggestedTemplate,
  }) = Rivalry;

  const factory CardData.tableStandings({
    @Default('N/A') String leagueName,
    @Default('N/A') String matchday,
    @Default([]) List<TableRow> standings,
    @Default('N/A') String highlightedTeam,
    @Default(4) int promotionZone,
    @Default(18) int relegationZone,
    @Default('N/A') String gamesInHand,
    @Default('N/A') String pointsBehindLeader,
    @Default('N/A') String topScorer,
    @Default('N/A') String topAssists,
    CardTemplate? suggestedTemplate,
  }) = TableStandings;

  const factory CardData.injuryReport({
    @Default('N/A') String teamName,
    @Default('N/A') String reportDate,
    @Default([]) List<InjuryItem> injuries,
    @Default([]) List<InjuryItem> doubtfits,
    @Default([]) List<InjuryItem> returns,
    @Default('N/A') String nextMatch,
    @Default('N/A') String recoveryPercentage,
    CardTemplate? suggestedTemplate,
  }) = InjuryReport;

  const factory CardData.contractExpiry({
    @Default('N/A') String teamName,
    @Default('N/A') String seasonYear,
    @Default([]) List<ContractPlayer> expiringPlayers,
    @Default([]) List<ContractPlayer> renewals,
    @Default('N/A') String wage,
    @Default('N/A') String askingPrice,
    @Default('N/A') String interestLevel,
    CardTemplate? suggestedTemplate,
  }) = ContractExpiry;

  const factory CardData.awardNominee({
    @Default('N/A') String awardName,
    @Default('N/A') String category,
    @Default([]) List<NomineeItem> nominees,
    @Default('N/A') String ceremonyDate,
    @Default('N/A') String currentFavorite,
    @Default('N/A') String votingDeadline,
    @Default('N/A') String votingMethod,
    @Default(0) int totalNominees,
    @Default('N/A') String venue,
    @Default('N/A') String host,
    CardTemplate? suggestedTemplate,
  }) = AwardNominee;

  // Sparse lightweight fallback — used when LLM returns old generic schema
  const factory CardData.sparse({
    @Default('Generated Card') String headline,
    @Default('') String subtext,
    String? microStat,
    CardTemplate? suggestedTemplate,
  }) = SparseCard;

  factory CardData.fromJson(Map<String, dynamic> json) =>
      _$CardDataFromJson(json);

  // Convenience for CardBrief → sparse
  factory CardData.fromBrief({
    required String headline,
    required String subtext,
    String? microStat,
  }) {
    return CardData.sparse(
      headline: headline.isEmpty ? 'Generated Card' : headline,
      subtext: subtext,
      microStat: microStat,
    );
  }

  // Sparse canonical accessors — all variants expose headline/subtext/microStat via switch
  String get headline {
    return switch (this) {
      PlayerSpotlight(:final playerName) => playerName,
      HeadlineQuote(:final headline) => headline,
      TopStats(:final matchContext) =>
        matchContext == 'N/A' ? 'Top Stats' : matchContext,
      TransferNews(:final playerName) => playerName,
      BreakingNews(:final headline) => headline,
      MatchPreview(:final homeTeam, :final awayTeam) =>
        '$homeTeam vs $awayTeam',
      DetailedScoreboard(
        :final homeTeam,
        :final awayTeam,
        :final homeScore,
        :final awayScore,
      ) =>
        '$homeTeam $homeScore - $awayScore $awayTeam',
      OnThisDay(:final headline) =>
        headline == 'N/A' ? 'On This Day' : headline,
      StartingXI(:final teamName, :final formation) => '$teamName $formation',
      MatchStatsComparison(:final homeTeam, :final awayTeam) =>
        '$homeTeam vs $awayTeam',
      SocialPost(:final content) =>
        content == 'N/A' ? 'Social Post' : content.split('\n').first,
      Rivalry(:final player1Name, :final player2Name) =>
        '$player1Name vs $player2Name',
      TableStandings(:final leagueName) =>
        leagueName == 'N/A' ? 'League Standings' : leagueName,
      InjuryReport(:final teamName) =>
        teamName == 'N/A' ? 'Injury Report' : teamName,
      ContractExpiry(:final teamName) =>
        teamName == 'N/A' ? 'Expiring Contracts' : teamName,
      AwardNominee(:final awardName) =>
        awardName == 'N/A' ? 'Award Nominees' : awardName,
      SparseCard(:final headline) => headline,
    };
  }

  String get subtext {
    return switch (this) {
      PlayerSpotlight(:final keyQuote) => keyQuote == 'N/A' ? '' : keyQuote,
      HeadlineQuote(:final subtext) => subtext == 'N/A' ? '' : subtext,
      TopStats(:final stats) =>
        stats.isEmpty
            ? ''
            : stats.map((s) => '${s.label}: ${s.value}').join(' • '),
      TransferNews(:final quote) => quote == 'N/A' ? '' : quote,
      BreakingNews(:final subtext) => subtext == 'N/A' ? '' : subtext,
      MatchPreview(:final competition, :final matchTime, :final stadium) =>
        '$competition • $matchTime • $stadium',
      DetailedScoreboard(:final competition, :final matchStatus) =>
        '$competition • $matchStatus',
      OnThisDay(:final significance) =>
        significance == 'N/A' ? '' : significance,
      StartingXI(:final manager) => manager == 'N/A' ? '' : 'Manager: $manager',
      MatchStatsComparison(:final stats) =>
        stats.isEmpty ? '' : '${stats.length} stats',
      SocialPost(:final metrics) => metrics == 'N/A' ? '' : metrics,
      Rivalry(:final verdict) => verdict == 'N/A' ? '' : verdict,
      TableStandings(:final matchday) => matchday == 'N/A' ? '' : matchday,
      InjuryReport(:final nextMatch) => nextMatch == 'N/A' ? '' : nextMatch,
      ContractExpiry(:final seasonYear) =>
        seasonYear == 'N/A' ? '' : seasonYear,
      AwardNominee(:final category) => category == 'N/A' ? '' : category,
      SparseCard(:final subtext) => subtext,
    };
  }

  String? get microStat {
    return switch (this) {
      PlayerSpotlight(:final keyAction) =>
        keyAction == 'N/A' ? null : keyAction,
      HeadlineQuote(:final category) => category == 'N/A' ? null : category,
      TopStats() => null,
      TransferNews(:final fee) => fee == 'N/A' ? null : fee,
      BreakingNews(:final label) => label,
      MatchPreview(:final homeForm) => homeForm == 'N/A' ? null : homeForm,
      DetailedScoreboard(:final possession) =>
        possession == 'N/A' ? null : possession,
      OnThisDay(:final yearsAgo) =>
        yearsAgo == 0 ? null : '$yearsAgo years ago',
      StartingXI(:final formation) => formation == 'N/A' ? null : formation,
      MatchStatsComparison() => null,
      SocialPost(:final handle) => handle == 'N/A' ? null : handle,
      Rivalry(:final headToHead) => headToHead == 'N/A' ? null : headToHead,
      TableStandings(:final highlightedTeam) =>
        highlightedTeam == 'N/A' ? null : highlightedTeam,
      InjuryReport(:final recoveryPercentage) =>
        recoveryPercentage == 'N/A' ? null : recoveryPercentage,
      ContractExpiry(:final wage) => wage == 'N/A' ? null : wage,
      AwardNominee(:final currentFavorite) =>
        currentFavorite == 'N/A' ? null : currentFavorite,
      SparseCard(:final microStat) => microStat,
    };
  }

  String get title => headline;
  String get subtitle => subtext;
  bool get hasMicroStat => microStat != null && microStat!.isNotEmpty;
  bool get isEmpty =>
      headline == 'Generated Card' && subtext.isEmpty && !hasMicroStat;

  CardTemplate get effectiveTemplate {
    final suggested = suggestedTemplate;
    if (suggested != null) return suggested;
    return switch (this) {
      PlayerSpotlight() => CardTemplate.playerSpotlight,
      HeadlineQuote() => CardTemplate.headlineQuote,
      TopStats() => CardTemplate.topStats,
      TransferNews() => CardTemplate.transferNews,
      BreakingNews() => CardTemplate.breakingNews,
      MatchPreview() => CardTemplate.matchPreview,
      DetailedScoreboard() => CardTemplate.detailedScoreboard,
      OnThisDay() => CardTemplate.onThisDay,
      StartingXI() => CardTemplate.startingXI,
      MatchStatsComparison() => CardTemplate.matchStatsComparison,
      SocialPost() => CardTemplate.socialPost,
      Rivalry() => CardTemplate.rivalry,
      TableStandings() => CardTemplate.tableStandings,
      InjuryReport() => CardTemplate.injuryReport,
      ContractExpiry() => CardTemplate.contractExpiry,
      AwardNominee() => CardTemplate.awardNominee,
      SparseCard() => CardTemplate.socialPost,
    };
  }
}

extension CardDataCopy on CardData {
  CardData copyWithHeadline(String headline) {
    return switch (this) {
      PlayerSpotlight() => (this as PlayerSpotlight).copyWith(
        playerName: headline,
      ),
      HeadlineQuote() => (this as HeadlineQuote).copyWith(headline: headline),
      BreakingNews() => (this as BreakingNews).copyWith(headline: headline),
      SparseCard() => (this as SparseCard).copyWith(headline: headline),
      _ => this,
    };
  }

  CardData adaptToTemplate(CardTemplate target) {
    if (effectiveTemplate == target) return this;
    final h = headline;
    final s = subtext;
    final m = microStat ?? 'N/A';

    // Smart context extraction from existing data if available
    String smartPlayerName = h;
    String smartClub = 'N/A';
    String smartQuote = s.isEmpty ? 'N/A' : s;
    String smartCategory = m;

    if (this is PlayerSpotlight) {
      final p = this as PlayerSpotlight;
      if (p.playerName != 'N/A') smartPlayerName = p.playerName;
      if (p.club != 'N/A') smartClub = p.club;
      if (p.keyQuote != 'N/A') smartQuote = p.keyQuote;
      if (p.keyAction != 'N/A') smartCategory = p.keyAction;
    } else if (this is TransferNews) {
      final t = this as TransferNews;
      if (t.playerName != 'N/A') smartPlayerName = t.playerName;
      if (t.fromTeam != 'N/A') smartClub = t.fromTeam;
      if (t.quote != 'N/A') smartQuote = t.quote;
      if (t.fee != 'N/A') smartCategory = t.fee;
    } else if (this is HeadlineQuote) {
      final q = this as HeadlineQuote;
      if (q.quoteAuthor != 'N/A') smartPlayerName = q.quoteAuthor;
      if (q.authorTitle != 'N/A') smartClub = q.authorTitle;
      if (q.subtext != 'N/A') smartQuote = q.subtext;
      if (q.category != 'N/A') smartCategory = q.category;
    }

    return switch (target) {
      CardTemplate.playerSpotlight =>
        this is PlayerSpotlight
            ? this
            : CardData.playerSpotlight(
                playerName: smartPlayerName,
                club: smartClub,
                keyQuote: smartQuote,
                keyAction: smartCategory,
              ),
      CardTemplate.headlineQuote =>
        this is HeadlineQuote
            ? this
            : CardData.headlineQuote(
                headline: h,
                subtext: smartQuote,
                quoteAuthor: smartPlayerName != h ? smartPlayerName : 'N/A',
                authorTitle: smartClub,
                category: smartCategory,
              ),
      CardTemplate.topStats =>
        this is TopStats ? this : CardData.topStats(matchContext: h),
      CardTemplate.transferNews =>
        this is TransferNews
            ? this
            : CardData.transferNews(
                playerName: smartPlayerName,
                fromTeam: smartClub,
                toTeam: 'N/A',
                quote: smartQuote,
                fee: smartCategory,
                action: 'TRANSFER ALERT',
              ),
      CardTemplate.breakingNews =>
        this is BreakingNews
            ? this
            : CardData.breakingNews(
                headline: h,
                subtext: s,
                label: m == 'N/A' ? 'BREAKING' : m,
              ),
      CardTemplate.matchPreview =>
        this is MatchPreview
            ? this
            : CardData.matchPreview(
                homeTeam: smartClub != 'N/A' ? smartClub : h,
                awayTeam: s.isEmpty ? 'Opponent' : s,
              ),
      CardTemplate.detailedScoreboard =>
        this is DetailedScoreboard
            ? this
            : CardData.detailedScoreboard(
                homeTeam: smartClub != 'N/A' ? smartClub : h,
                awayTeam: s.isEmpty ? 'Opponent' : s,
              ),
      CardTemplate.onThisDay =>
        this is OnThisDay
            ? this
            : CardData.onThisDay(
                headline: h,
                significance: s.isEmpty ? 'N/A' : s,
              ),
      CardTemplate.startingXI =>
        this is StartingXI
            ? this
            : CardData.startingXI(
                teamName: smartClub != 'N/A' ? smartClub : h,
                formation: m == 'N/A' ? '4-3-3' : m,
              ),
      CardTemplate.matchStatsComparison =>
        this is MatchStatsComparison
            ? this
            : CardData.matchStatsComparison(
                homeTeam: smartClub != 'N/A' ? smartClub : h,
                awayTeam: s.isEmpty ? 'Opponent' : s,
              ),
      CardTemplate.socialPost =>
        this is SocialPost
            ? this
            : CardData.socialPost(
                content: s.isNotEmpty ? '$h\n\n$s' : h,
                metrics: s,
                handle: m,
              ),
      CardTemplate.rivalry =>
        this is Rivalry
            ? this
            : CardData.rivalry(
                player1Name: smartPlayerName,
                player2Name: s.isEmpty ? 'Rival' : s,
              ),
      CardTemplate.tableStandings =>
        this is TableStandings
            ? this
            : CardData.tableStandings(
                leagueName: h,
                matchday: s.isEmpty ? 'N/A' : s,
              ),
      CardTemplate.injuryReport =>
        this is InjuryReport
            ? this
            : CardData.injuryReport(
                teamName: smartClub != 'N/A' ? smartClub : h,
                nextMatch: s.isEmpty ? 'N/A' : s,
              ),
      CardTemplate.contractExpiry =>
        this is ContractExpiry
            ? this
            : CardData.contractExpiry(
                teamName: smartClub != 'N/A' ? smartClub : h,
                seasonYear: s.isEmpty ? 'N/A' : s,
              ),
      CardTemplate.awardNominee =>
        this is AwardNominee
            ? this
            : CardData.awardNominee(
                awardName: h,
                category: s.isEmpty ? 'N/A' : s,
              ),
      CardTemplate.freeform =>
        this is SparseCard && suggestedTemplate == CardTemplate.freeform
            ? this
            : CardData.sparse(
                headline: h,
                subtext: s,
                microStat: m == 'N/A' ? null : m,
                suggestedTemplate: CardTemplate.freeform,
              ),
    };
  }
}
