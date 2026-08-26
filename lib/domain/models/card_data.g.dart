// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatItem _$StatItemFromJson(Map<String, dynamic> json) => _StatItem(
  label: json['label'] as String,
  value: json['value'] as String,
  context: json['context'] as String? ?? 'N/A',
);

Map<String, dynamic> _$StatItemToJson(_StatItem instance) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
  'context': instance.context,
};

_ComparisonStat _$ComparisonStatFromJson(Map<String, dynamic> json) =>
    _ComparisonStat(
      label: json['label'] as String,
      homeValue: json['homeValue'] as String,
      awayValue: json['awayValue'] as String,
    );

Map<String, dynamic> _$ComparisonStatToJson(_ComparisonStat instance) =>
    <String, dynamic>{
      'label': instance.label,
      'homeValue': instance.homeValue,
      'awayValue': instance.awayValue,
    };

_LineupPlayer _$LineupPlayerFromJson(Map<String, dynamic> json) =>
    _LineupPlayer(
      number: json['number'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LineupPlayerToJson(_LineupPlayer instance) =>
    <String, dynamic>{'number': instance.number, 'name': instance.name};

_TableRow _$TableRowFromJson(Map<String, dynamic> json) => _TableRow(
  position: (json['position'] as num).toInt(),
  teamName: json['teamName'] as String,
  played: (json['played'] as num).toInt(),
  won: (json['won'] as num).toInt(),
  drawn: (json['drawn'] as num).toInt(),
  lost: (json['lost'] as num).toInt(),
  points: (json['points'] as num).toInt(),
  form: json['form'] as String? ?? 'N/A',
);

Map<String, dynamic> _$TableRowToJson(_TableRow instance) => <String, dynamic>{
  'position': instance.position,
  'teamName': instance.teamName,
  'played': instance.played,
  'won': instance.won,
  'drawn': instance.drawn,
  'lost': instance.lost,
  'points': instance.points,
  'form': instance.form,
};

_InjuryItem _$InjuryItemFromJson(Map<String, dynamic> json) => _InjuryItem(
  playerName: json['playerName'] as String,
  injury: json['injury'] as String,
  status: json['status'] as String,
  position: json['position'] as String? ?? 'N/A',
  recoveryPercentage: json['recoveryPercentage'] as String? ?? 'N/A',
  isLongTerm: json['isLongTerm'] as bool? ?? false,
  surgeryRequired: json['surgeryRequired'] as bool? ?? false,
);

Map<String, dynamic> _$InjuryItemToJson(_InjuryItem instance) =>
    <String, dynamic>{
      'playerName': instance.playerName,
      'injury': instance.injury,
      'status': instance.status,
      'position': instance.position,
      'recoveryPercentage': instance.recoveryPercentage,
      'isLongTerm': instance.isLongTerm,
      'surgeryRequired': instance.surgeryRequired,
    };

_ContractPlayer _$ContractPlayerFromJson(Map<String, dynamic> json) =>
    _ContractPlayer(
      playerName: json['playerName'] as String,
      position: json['position'] as String,
      expiresIn: json['expiresIn'] as String,
      marketValue: json['marketValue'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'N/A',
      wage: json['wage'] as String? ?? 'N/A',
      askingPrice: json['askingPrice'] as String? ?? 'N/A',
      interestLevel: json['interestLevel'] as String? ?? 'N/A',
      negotiationProgress: json['negotiationProgress'] as String? ?? 'N/A',
      previousClub: json['previousClub'] as String? ?? 'N/A',
    );

Map<String, dynamic> _$ContractPlayerToJson(_ContractPlayer instance) =>
    <String, dynamic>{
      'playerName': instance.playerName,
      'position': instance.position,
      'expiresIn': instance.expiresIn,
      'marketValue': instance.marketValue,
      'status': instance.status,
      'wage': instance.wage,
      'askingPrice': instance.askingPrice,
      'interestLevel': instance.interestLevel,
      'negotiationProgress': instance.negotiationProgress,
      'previousClub': instance.previousClub,
    };

_NomineeItem _$NomineeItemFromJson(Map<String, dynamic> json) => _NomineeItem(
  playerName: json['playerName'] as String,
  club: json['club'] as String,
  achievement: json['achievement'] as String,
  odds: json['odds'] as String? ?? 'N/A',
  isFavorite: json['isFavorite'] as bool? ?? false,
  previousWinner: json['previousWinner'] as bool? ?? false,
  votes: json['votes'] as String? ?? 'N/A',
);

Map<String, dynamic> _$NomineeItemToJson(_NomineeItem instance) =>
    <String, dynamic>{
      'playerName': instance.playerName,
      'club': instance.club,
      'achievement': instance.achievement,
      'odds': instance.odds,
      'isFavorite': instance.isFavorite,
      'previousWinner': instance.previousWinner,
      'votes': instance.votes,
    };

PlayerSpotlight _$PlayerSpotlightFromJson(Map<String, dynamic> json) =>
    PlayerSpotlight(
      playerName: json['playerName'] as String,
      club: json['club'] as String? ?? 'N/A',
      position: json['position'] as String? ?? 'N/A',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      minutesPlayed: (json['minutesPlayed'] as num?)?.toInt() ?? 0,
      keyAction: json['keyAction'] as String? ?? 'N/A',
      keyQuote: json['keyQuote'] as String? ?? 'N/A',
      nationality: json['nationality'] as String? ?? 'N/A',
      appearances: (json['appearances'] as num?)?.toInt() ?? 0,
      cleanSheets: (json['cleanSheets'] as num?)?.toInt() ?? 0,
      passes: (json['passes'] as num?)?.toInt() ?? 0,
      tackles: (json['tackles'] as num?)?.toInt() ?? 0,
      suggestedTemplate: $enumDecodeNullable(
        _$CardTemplateEnumMap,
        json['suggestedTemplate'],
      ),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$PlayerSpotlightToJson(PlayerSpotlight instance) =>
    <String, dynamic>{
      'playerName': instance.playerName,
      'club': instance.club,
      'position': instance.position,
      'rating': instance.rating,
      'goals': instance.goals,
      'assists': instance.assists,
      'minutesPlayed': instance.minutesPlayed,
      'keyAction': instance.keyAction,
      'keyQuote': instance.keyQuote,
      'nationality': instance.nationality,
      'appearances': instance.appearances,
      'cleanSheets': instance.cleanSheets,
      'passes': instance.passes,
      'tackles': instance.tackles,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

const _$CardTemplateEnumMap = {
  CardTemplate.playerSpotlight: 'playerSpotlight',
  CardTemplate.headlineQuote: 'headlineQuote',
  CardTemplate.topStats: 'topStats',
  CardTemplate.transferNews: 'transferNews',
  CardTemplate.breakingNews: 'breakingNews',
  CardTemplate.matchPreview: 'matchPreview',
  CardTemplate.detailedScoreboard: 'detailedScoreboard',
  CardTemplate.onThisDay: 'onThisDay',
  CardTemplate.startingXI: 'startingXI',
  CardTemplate.matchStatsComparison: 'matchStatsComparison',
  CardTemplate.socialPost: 'socialPost',
  CardTemplate.rivalry: 'rivalry',
  CardTemplate.tableStandings: 'tableStandings',
  CardTemplate.injuryReport: 'injuryReport',
  CardTemplate.contractExpiry: 'contractExpiry',
  CardTemplate.awardNominee: 'awardNominee',
  CardTemplate.freeform: 'freeform',
};

HeadlineQuote _$HeadlineQuoteFromJson(Map<String, dynamic> json) =>
    HeadlineQuote(
      headline: json['headline'] as String,
      subtext: json['subtext'] as String,
      quoteAuthor: json['quoteAuthor'] as String? ?? 'N/A',
      authorTitle: json['authorTitle'] as String? ?? 'N/A',
      category: json['category'] as String? ?? 'N/A',
      relatedTeams: json['relatedTeams'] as String? ?? 'N/A',
      suggestedTemplate: $enumDecodeNullable(
        _$CardTemplateEnumMap,
        json['suggestedTemplate'],
      ),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$HeadlineQuoteToJson(HeadlineQuote instance) =>
    <String, dynamic>{
      'headline': instance.headline,
      'subtext': instance.subtext,
      'quoteAuthor': instance.quoteAuthor,
      'authorTitle': instance.authorTitle,
      'category': instance.category,
      'relatedTeams': instance.relatedTeams,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

TopStats _$TopStatsFromJson(Map<String, dynamic> json) => TopStats(
  matchContext: json['matchContext'] as String? ?? 'N/A',
  stats:
      (json['stats'] as List<dynamic>?)
          ?.map((e) => StatItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TopStatsToJson(TopStats instance) => <String, dynamic>{
  'matchContext': instance.matchContext,
  'stats': instance.stats,
  'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
  'runtimeType': instance.$type,
};

TransferNews _$TransferNewsFromJson(Map<String, dynamic> json) => TransferNews(
  playerName: json['playerName'] as String,
  action: json['action'] as String? ?? 'N/A',
  fromTeam: json['fromTeam'] as String? ?? 'N/A',
  toTeam: json['toTeam'] as String? ?? 'N/A',
  fee: json['fee'] as String? ?? 'N/A',
  contractLength: json['contractLength'] as String? ?? 'N/A',
  transferType: json['transferType'] as String? ?? 'N/A',
  quote: json['quote'] as String? ?? 'N/A',
  feeCategory: json['feeCategory'] as String? ?? 'N/A',
  medicalCompleted: json['medicalCompleted'] as bool? ?? false,
  workPermit: json['workPermit'] as bool? ?? false,
  agentName: json['agentName'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TransferNewsToJson(TransferNews instance) =>
    <String, dynamic>{
      'playerName': instance.playerName,
      'action': instance.action,
      'fromTeam': instance.fromTeam,
      'toTeam': instance.toTeam,
      'fee': instance.fee,
      'contractLength': instance.contractLength,
      'transferType': instance.transferType,
      'quote': instance.quote,
      'feeCategory': instance.feeCategory,
      'medicalCompleted': instance.medicalCompleted,
      'workPermit': instance.workPermit,
      'agentName': instance.agentName,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

BreakingNews _$BreakingNewsFromJson(Map<String, dynamic> json) => BreakingNews(
  label: json['label'] as String? ?? '🚨 BREAKING',
  headline: json['headline'] as String,
  subtext: json['subtext'] as String? ?? 'N/A',
  impactRating: (json['impactRating'] as num?)?.toInt() ?? 3,
  relatedTeams: json['relatedTeams'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$BreakingNewsToJson(BreakingNews instance) =>
    <String, dynamic>{
      'label': instance.label,
      'headline': instance.headline,
      'subtext': instance.subtext,
      'impactRating': instance.impactRating,
      'relatedTeams': instance.relatedTeams,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

MatchPreview _$MatchPreviewFromJson(Map<String, dynamic> json) => MatchPreview(
  competition: json['competition'] as String? ?? 'N/A',
  homeTeam: json['homeTeam'] as String,
  awayTeam: json['awayTeam'] as String,
  homeForm: json['homeForm'] as String? ?? 'N/A',
  awayForm: json['awayForm'] as String? ?? 'N/A',
  matchTime: json['matchTime'] as String? ?? 'N/A',
  stadium: json['stadium'] as String? ?? 'N/A',
  referee: json['referee'] as String? ?? 'N/A',
  tvChannel: json['tvChannel'] as String? ?? 'N/A',
  kickoffTime: json['kickoffTime'] as String? ?? 'N/A',
  weather: json['weather'] as String? ?? 'N/A',
  capacity: json['capacity'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$MatchPreviewToJson(MatchPreview instance) =>
    <String, dynamic>{
      'competition': instance.competition,
      'homeTeam': instance.homeTeam,
      'awayTeam': instance.awayTeam,
      'homeForm': instance.homeForm,
      'awayForm': instance.awayForm,
      'matchTime': instance.matchTime,
      'stadium': instance.stadium,
      'referee': instance.referee,
      'tvChannel': instance.tvChannel,
      'kickoffTime': instance.kickoffTime,
      'weather': instance.weather,
      'capacity': instance.capacity,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

DetailedScoreboard _$DetailedScoreboardFromJson(Map<String, dynamic> json) =>
    DetailedScoreboard(
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      homeScore: (json['homeScore'] as num?)?.toInt() ?? 0,
      awayScore: (json['awayScore'] as num?)?.toInt() ?? 0,
      homeScorers: json['homeScorers'] as String? ?? 'N/A',
      awayScorers: json['awayScorers'] as String? ?? 'N/A',
      possession: json['possession'] as String? ?? 'N/A',
      shotsOnTarget: json['shotsOnTarget'] as String? ?? 'N/A',
      competition: json['competition'] as String? ?? 'N/A',
      matchStatus: json['matchStatus'] as String? ?? 'N/A',
      corners: json['corners'] as String? ?? 'N/A',
      fouls: json['fouls'] as String? ?? 'N/A',
      yellowCards: json['yellowCards'] as String? ?? 'N/A',
      redCards: json['redCards'] as String? ?? 'N/A',
      attendance: json['attendance'] as String? ?? 'N/A',
      referee: json['referee'] as String? ?? 'N/A',
      penaltyShootout: json['penaltyShootout'] as String? ?? 'N/A',
      assistProviders: json['assistProviders'] as String? ?? 'N/A',
      suggestedTemplate: $enumDecodeNullable(
        _$CardTemplateEnumMap,
        json['suggestedTemplate'],
      ),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$DetailedScoreboardToJson(DetailedScoreboard instance) =>
    <String, dynamic>{
      'homeTeam': instance.homeTeam,
      'awayTeam': instance.awayTeam,
      'homeScore': instance.homeScore,
      'awayScore': instance.awayScore,
      'homeScorers': instance.homeScorers,
      'awayScorers': instance.awayScorers,
      'possession': instance.possession,
      'shotsOnTarget': instance.shotsOnTarget,
      'competition': instance.competition,
      'matchStatus': instance.matchStatus,
      'corners': instance.corners,
      'fouls': instance.fouls,
      'yellowCards': instance.yellowCards,
      'redCards': instance.redCards,
      'attendance': instance.attendance,
      'referee': instance.referee,
      'penaltyShootout': instance.penaltyShootout,
      'assistProviders': instance.assistProviders,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

OnThisDay _$OnThisDayFromJson(Map<String, dynamic> json) => OnThisDay(
  dateLabel: json['dateLabel'] as String? ?? 'N/A',
  yearsAgo: (json['yearsAgo'] as num?)?.toInt() ?? 0,
  competition: json['competition'] as String? ?? 'N/A',
  headline: json['headline'] as String? ?? 'N/A',
  keyStats:
      (json['keyStats'] as List<dynamic>?)
          ?.map((e) => StatItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  venue: json['venue'] as String? ?? 'N/A',
  attendance: json['attendance'] as String? ?? 'N/A',
  result: json['result'] as String? ?? 'N/A',
  significance: json['significance'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$OnThisDayToJson(OnThisDay instance) => <String, dynamic>{
  'dateLabel': instance.dateLabel,
  'yearsAgo': instance.yearsAgo,
  'competition': instance.competition,
  'headline': instance.headline,
  'keyStats': instance.keyStats,
  'venue': instance.venue,
  'attendance': instance.attendance,
  'result': instance.result,
  'significance': instance.significance,
  'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
  'runtimeType': instance.$type,
};

StartingXI _$StartingXIFromJson(Map<String, dynamic> json) => StartingXI(
  teamName: json['teamName'] as String? ?? 'N/A',
  formation: json['formation'] as String? ?? 'N/A',
  starters:
      (json['starters'] as List<dynamic>?)
          ?.map((e) => LineupPlayer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  subs:
      (json['subs'] as List<dynamic>?)
          ?.map((e) => LineupPlayer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  manager: json['manager'] as String? ?? 'N/A',
  averageAge: json['averageAge'] as String? ?? 'N/A',
  keyAbsences: json['keyAbsences'] as String? ?? 'N/A',
  captain: json['captain'] as String? ?? 'N/A',
  viceCaptain: json['viceCaptain'] as String? ?? 'N/A',
  tactics: json['tactics'] as String? ?? 'N/A',
  injuredPlayers: json['injuredPlayers'] as String? ?? 'N/A',
  suspendedPlayers: json['suspendedPlayers'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$StartingXIToJson(StartingXI instance) =>
    <String, dynamic>{
      'teamName': instance.teamName,
      'formation': instance.formation,
      'starters': instance.starters,
      'subs': instance.subs,
      'manager': instance.manager,
      'averageAge': instance.averageAge,
      'keyAbsences': instance.keyAbsences,
      'captain': instance.captain,
      'viceCaptain': instance.viceCaptain,
      'tactics': instance.tactics,
      'injuredPlayers': instance.injuredPlayers,
      'suspendedPlayers': instance.suspendedPlayers,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

MatchStatsComparison _$MatchStatsComparisonFromJson(
  Map<String, dynamic> json,
) => MatchStatsComparison(
  homeTeam: json['homeTeam'] as String? ?? 'N/A',
  awayTeam: json['awayTeam'] as String? ?? 'N/A',
  stats:
      (json['stats'] as List<dynamic>?)
          ?.map((e) => ComparisonStat.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$MatchStatsComparisonToJson(
  MatchStatsComparison instance,
) => <String, dynamic>{
  'homeTeam': instance.homeTeam,
  'awayTeam': instance.awayTeam,
  'stats': instance.stats,
  'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
  'runtimeType': instance.$type,
};

SocialPost _$SocialPostFromJson(Map<String, dynamic> json) => SocialPost(
  handle: json['handle'] as String? ?? 'N/A',
  name: json['name'] as String? ?? 'N/A',
  content: json['content'] as String? ?? 'N/A',
  timestamp: json['timestamp'] as String? ?? 'N/A',
  metrics: json['metrics'] as String? ?? 'N/A',
  verified: json['verified'] as bool? ?? false,
  followers: json['followers'] as String? ?? 'N/A',
  shares: json['shares'] as String? ?? 'N/A',
  bookmarks: json['bookmarks'] as String? ?? 'N/A',
  mediaType: json['mediaType'] as String? ?? 'N/A',
  isEdited: json['isEdited'] as bool? ?? false,
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SocialPostToJson(SocialPost instance) =>
    <String, dynamic>{
      'handle': instance.handle,
      'name': instance.name,
      'content': instance.content,
      'timestamp': instance.timestamp,
      'metrics': instance.metrics,
      'verified': instance.verified,
      'followers': instance.followers,
      'shares': instance.shares,
      'bookmarks': instance.bookmarks,
      'mediaType': instance.mediaType,
      'isEdited': instance.isEdited,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

Rivalry _$RivalryFromJson(Map<String, dynamic> json) => Rivalry(
  player1Name: json['player1Name'] as String? ?? 'N/A',
  player2Name: json['player2Name'] as String? ?? 'N/A',
  matchContext: json['matchContext'] as String? ?? 'N/A',
  player1Stats:
      (json['player1Stats'] as List<dynamic>?)
          ?.map((e) => StatItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  player2Stats:
      (json['player2Stats'] as List<dynamic>?)
          ?.map((e) => StatItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  headToHead: json['headToHead'] as String? ?? 'N/A',
  verdict: json['verdict'] as String? ?? 'N/A',
  compareType: json['compareType'] as String? ?? 'N/A',
  totalMatches: json['totalMatches'] as String? ?? 'N/A',
  draws: json['draws'] as String? ?? 'N/A',
  player1Trophies: json['player1Trophies'] as String? ?? 'N/A',
  player2Trophies: json['player2Trophies'] as String? ?? 'N/A',
  predictionConfidence: json['predictionConfidence'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$RivalryToJson(Rivalry instance) => <String, dynamic>{
  'player1Name': instance.player1Name,
  'player2Name': instance.player2Name,
  'matchContext': instance.matchContext,
  'player1Stats': instance.player1Stats,
  'player2Stats': instance.player2Stats,
  'headToHead': instance.headToHead,
  'verdict': instance.verdict,
  'compareType': instance.compareType,
  'totalMatches': instance.totalMatches,
  'draws': instance.draws,
  'player1Trophies': instance.player1Trophies,
  'player2Trophies': instance.player2Trophies,
  'predictionConfidence': instance.predictionConfidence,
  'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
  'runtimeType': instance.$type,
};

TableStandings _$TableStandingsFromJson(Map<String, dynamic> json) =>
    TableStandings(
      leagueName: json['leagueName'] as String? ?? 'N/A',
      matchday: json['matchday'] as String? ?? 'N/A',
      standings:
          (json['standings'] as List<dynamic>?)
              ?.map((e) => TableRow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      highlightedTeam: json['highlightedTeam'] as String? ?? 'N/A',
      promotionZone: (json['promotionZone'] as num?)?.toInt() ?? 4,
      relegationZone: (json['relegationZone'] as num?)?.toInt() ?? 18,
      gamesInHand: json['gamesInHand'] as String? ?? 'N/A',
      pointsBehindLeader: json['pointsBehindLeader'] as String? ?? 'N/A',
      topScorer: json['topScorer'] as String? ?? 'N/A',
      topAssists: json['topAssists'] as String? ?? 'N/A',
      suggestedTemplate: $enumDecodeNullable(
        _$CardTemplateEnumMap,
        json['suggestedTemplate'],
      ),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$TableStandingsToJson(TableStandings instance) =>
    <String, dynamic>{
      'leagueName': instance.leagueName,
      'matchday': instance.matchday,
      'standings': instance.standings,
      'highlightedTeam': instance.highlightedTeam,
      'promotionZone': instance.promotionZone,
      'relegationZone': instance.relegationZone,
      'gamesInHand': instance.gamesInHand,
      'pointsBehindLeader': instance.pointsBehindLeader,
      'topScorer': instance.topScorer,
      'topAssists': instance.topAssists,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

InjuryReport _$InjuryReportFromJson(Map<String, dynamic> json) => InjuryReport(
  teamName: json['teamName'] as String? ?? 'N/A',
  reportDate: json['reportDate'] as String? ?? 'N/A',
  injuries:
      (json['injuries'] as List<dynamic>?)
          ?.map((e) => InjuryItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  doubtfits:
      (json['doubtfits'] as List<dynamic>?)
          ?.map((e) => InjuryItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  returns:
      (json['returns'] as List<dynamic>?)
          ?.map((e) => InjuryItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  nextMatch: json['nextMatch'] as String? ?? 'N/A',
  recoveryPercentage: json['recoveryPercentage'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$InjuryReportToJson(InjuryReport instance) =>
    <String, dynamic>{
      'teamName': instance.teamName,
      'reportDate': instance.reportDate,
      'injuries': instance.injuries,
      'doubtfits': instance.doubtfits,
      'returns': instance.returns,
      'nextMatch': instance.nextMatch,
      'recoveryPercentage': instance.recoveryPercentage,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

ContractExpiry _$ContractExpiryFromJson(Map<String, dynamic> json) =>
    ContractExpiry(
      teamName: json['teamName'] as String? ?? 'N/A',
      seasonYear: json['seasonYear'] as String? ?? 'N/A',
      expiringPlayers:
          (json['expiringPlayers'] as List<dynamic>?)
              ?.map((e) => ContractPlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      renewals:
          (json['renewals'] as List<dynamic>?)
              ?.map((e) => ContractPlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      wage: json['wage'] as String? ?? 'N/A',
      askingPrice: json['askingPrice'] as String? ?? 'N/A',
      interestLevel: json['interestLevel'] as String? ?? 'N/A',
      suggestedTemplate: $enumDecodeNullable(
        _$CardTemplateEnumMap,
        json['suggestedTemplate'],
      ),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ContractExpiryToJson(ContractExpiry instance) =>
    <String, dynamic>{
      'teamName': instance.teamName,
      'seasonYear': instance.seasonYear,
      'expiringPlayers': instance.expiringPlayers,
      'renewals': instance.renewals,
      'wage': instance.wage,
      'askingPrice': instance.askingPrice,
      'interestLevel': instance.interestLevel,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

AwardNominee _$AwardNomineeFromJson(Map<String, dynamic> json) => AwardNominee(
  awardName: json['awardName'] as String? ?? 'N/A',
  category: json['category'] as String? ?? 'N/A',
  nominees:
      (json['nominees'] as List<dynamic>?)
          ?.map((e) => NomineeItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  ceremonyDate: json['ceremonyDate'] as String? ?? 'N/A',
  currentFavorite: json['currentFavorite'] as String? ?? 'N/A',
  votingDeadline: json['votingDeadline'] as String? ?? 'N/A',
  votingMethod: json['votingMethod'] as String? ?? 'N/A',
  totalNominees: (json['totalNominees'] as num?)?.toInt() ?? 0,
  venue: json['venue'] as String? ?? 'N/A',
  host: json['host'] as String? ?? 'N/A',
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$AwardNomineeToJson(AwardNominee instance) =>
    <String, dynamic>{
      'awardName': instance.awardName,
      'category': instance.category,
      'nominees': instance.nominees,
      'ceremonyDate': instance.ceremonyDate,
      'currentFavorite': instance.currentFavorite,
      'votingDeadline': instance.votingDeadline,
      'votingMethod': instance.votingMethod,
      'totalNominees': instance.totalNominees,
      'venue': instance.venue,
      'host': instance.host,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };

SparseCard _$SparseCardFromJson(Map<String, dynamic> json) => SparseCard(
  headline: json['headline'] as String? ?? 'Generated Card',
  subtext: json['subtext'] as String? ?? '',
  microStat: json['microStat'] as String?,
  suggestedTemplate: $enumDecodeNullable(
    _$CardTemplateEnumMap,
    json['suggestedTemplate'],
  ),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SparseCardToJson(SparseCard instance) =>
    <String, dynamic>{
      'headline': instance.headline,
      'subtext': instance.subtext,
      'microStat': instance.microStat,
      'suggestedTemplate': _$CardTemplateEnumMap[instance.suggestedTemplate],
      'runtimeType': instance.$type,
    };
