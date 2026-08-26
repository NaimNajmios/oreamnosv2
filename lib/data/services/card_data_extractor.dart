import 'package:injectable/injectable.dart';

import 'dart:convert';

import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

@lazySingleton
class CardDataExtractor {
  static const String _na = 'N/A';

  Future<CardData> extractCardData({
    required CardBrief brief,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
    CardTemplate? template,
    bool isRefresh = false,
  }) async {
    final effectiveTemplate = template ?? CardTemplate.socialPost;
    final curator = CuratorFactory.getCurator(provider);
    final res = await curator.extractCardData(
      brief: brief,
      modelId: modelId,
      apiKey: apiKey,
      template: effectiveTemplate,
      isRefresh: isRefresh,
    );
    final jsonString = res;

    final cleanedJson = _stripFencesLenient(jsonString);

    try {
      final Map<String, dynamic> jsonMap = _parseLenient(cleanedJson);
      return _mapToCardData(jsonMap, effectiveTemplate, brief);
    } catch (e) {
      // Fallback: treat as sparse companion if rich parse fails
      try {
        final fallback = jsonDecode(cleanedJson) as Map<String, dynamic>;
        if (fallback.containsKey('headline') ||
            fallback.containsKey('content') ||
            fallback.containsKey('playerName')) {
          return _mapToCardData(fallback, effectiveTemplate, brief);
        }
      } catch (_) {}
      throw Exception('Failed to parse CardData JSON: $e\nRaw: $cleanedJson');
    }
  }

  // Lenient fence strip + bracket depth scan (Android parity)
  String _stripFencesLenient(String input) {
    var text = input.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();
    // Depth-counting bracket match for first { … }
    final start = text.indexOf('{');
    if (start == -1) return text;
    int depth = 0;
    int end = -1;
    for (int i = start; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    if (end != -1) {
      return text.substring(start, end + 1).trim();
    }
    // Fallback: last }
    final last = text.lastIndexOf('}');
    if (last > start) return text.substring(start, last + 1).trim();
    return text;
  }

  Map<String, dynamic> _parseLenient(String cleaned) {
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // Try to fix trailing commas (lenient)
      final fixed = cleaned
          .replaceAll(RegExp(r',\s*}'), '}')
          .replaceAll(RegExp(r',\s*]'), ']');
      return jsonDecode(fixed) as Map<String, dynamic>;
    }
  }

  String _s(Map<String, dynamic> m, String key, [String fallback = _na]) {
    final v = m[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty) return fallback;
    return s;
  }

  int _i(Map<String, dynamic> m, String key, [int fallback = 0]) {
    final v = m[key];
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double _d(Map<String, dynamic> m, String key, [double fallback = 0.0]) {
    final v = m[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  List<T> _list<T>(
    Map<String, dynamic> m,
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    int? exact,
  }) {
    final v = m[key];
    if (v is List) {
      final items = v.whereType<Map<String, dynamic>>().map(fromJson).toList();
      if (exact != null) {
        while (items.length < exact) {
          // Pad with N/A placeholder — handled via fallback in factory
          items.add(fromJson({}));
        }
        if (items.length > exact) return items.sublist(0, exact);
      }
      return items;
    }
    return [];
  }

  CardData _mapToCardData(
    Map<String, dynamic> json,
    CardTemplate requested,
    CardBrief brief,
  ) {
    // Intent routing
    final intent = json['template_intent'] as String?;
    final CardTemplate effective = intent != null
        ? CardTemplate.fromIntent(intent)
        : requested;

    // Helper to pad stats to exactly 3
    // ignore: no_leading_underscores_for_local_identifiers
    List<StatItem> stats3(Map<String, dynamic> m) {
      final list = _list(
        m,
        'stats',
        (j) => StatItem(
          label: _s(j, 'label', 'N/A'),
          value: _s(j, 'value', 'N/A'),
          context: _s(j, 'context', 'N/A'),
        ),
      );
      while (list.length < 3) {
        list.add(const StatItem(label: 'N/A', value: 'N/A', context: 'N/A'));
      }
      return list.take(3).toList();
    }

    final sparseHeadline = _s(
      json,
      'headline',
      brief.headline.isEmpty ? 'N/A' : brief.headline,
    );
    final sparseSubtext = _s(
      json,
      'subtext',
      brief.subtext.isEmpty ? 'N/A' : brief.subtext,
    );
    final sparseMicro =
        json['microStat'] as String? ?? json['keyAction'] as String?;

    switch (effective) {
      case CardTemplate.playerSpotlight:
        return CardData.playerSpotlight(
          playerName: _s(json, 'playerName', sparseHeadline),
          club: _s(json, 'club'),
          position: _s(json, 'position'),
          rating: _d(json, 'rating'),
          goals: _i(json, 'goals'),
          assists: _i(json, 'assists'),
          minutesPlayed: _i(json, 'minutesPlayed'),
          keyAction: sparseMicro ?? _s(json, 'keyAction'),
          keyQuote: _s(json, 'keyQuote', sparseSubtext),
          nationality: _s(json, 'nationality'),
          appearances: _i(json, 'appearances'),
          cleanSheets: _i(json, 'cleanSheets'),
          passes: _i(json, 'passes'),
          tackles: _i(json, 'tackles'),
          suggestedTemplate: effective,
        );
      case CardTemplate.headlineQuote:
        return CardData.headlineQuote(
          headline: _s(json, 'headline', sparseHeadline),
          subtext: _s(json, 'subtext', sparseSubtext),
          quoteAuthor: _s(json, 'quoteAuthor'),
          authorTitle: _s(json, 'authorTitle'),
          category: _s(json, 'category'),
          relatedTeams: _s(json, 'relatedTeams'),
          suggestedTemplate: effective,
        );
      case CardTemplate.topStats:
        return CardData.topStats(
          matchContext: _s(json, 'matchContext', sparseHeadline),
          stats: stats3(json),
          suggestedTemplate: effective,
        );
      case CardTemplate.transferNews:
        return CardData.transferNews(
          playerName: _s(json, 'playerName', sparseHeadline),
          action: _s(json, 'action'),
          fromTeam: _s(json, 'fromTeam'),
          toTeam: _s(json, 'toTeam'),
          fee: _s(json, 'fee', sparseMicro ?? 'N/A'),
          contractLength: _s(json, 'contractLength'),
          transferType: _s(json, 'transferType'),
          quote: _s(json, 'quote', sparseSubtext),
          feeCategory: _s(json, 'feeCategory'),
          medicalCompleted: json['medicalCompleted'] == true,
          workPermit: json['workPermit'] == true,
          agentName: _s(json, 'agentName'),
          suggestedTemplate: effective,
        );
      case CardTemplate.breakingNews:
        return CardData.breakingNews(
          label: _s(json, 'label', '🚨 BREAKING'),
          headline: _s(json, 'headline', sparseHeadline),
          subtext: _s(json, 'subtext', sparseSubtext),
          impactRating: _i(json, 'impactRating', 3),
          relatedTeams: _s(json, 'relatedTeams'),
          suggestedTemplate: effective,
        );
      case CardTemplate.matchPreview:
        return CardData.matchPreview(
          competition: _s(json, 'competition'),
          homeTeam: _s(json, 'homeTeam', 'N/A'),
          awayTeam: _s(json, 'awayTeam', 'N/A'),
          homeForm: _s(json, 'homeForm'),
          awayForm: _s(json, 'awayForm'),
          matchTime: _s(json, 'matchTime'),
          stadium: _s(json, 'stadium'),
          referee: _s(json, 'referee'),
          tvChannel: _s(json, 'tvChannel'),
          kickoffTime: _s(json, 'kickoffTime'),
          weather: _s(json, 'weather'),
          capacity: _s(json, 'capacity'),
          suggestedTemplate: effective,
        );
      case CardTemplate.detailedScoreboard:
        return CardData.detailedScoreboard(
          homeTeam: _s(json, 'homeTeam', 'N/A'),
          awayTeam: _s(json, 'awayTeam', 'N/A'),
          homeScore: _i(json, 'homeScore'),
          awayScore: _i(json, 'awayScore'),
          homeScorers: _s(json, 'homeScorers'),
          awayScorers: _s(json, 'awayScorers'),
          possession: _s(json, 'possession'),
          shotsOnTarget: _s(json, 'shotsOnTarget'),
          competition: _s(json, 'competition'),
          matchStatus: _s(json, 'matchStatus'),
          corners: _s(json, 'corners'),
          fouls: _s(json, 'fouls'),
          yellowCards: _s(json, 'yellowCards'),
          redCards: _s(json, 'redCards'),
          attendance: _s(json, 'attendance'),
          referee: _s(json, 'referee'),
          penaltyShootout: _s(json, 'penaltyShootout'),
          assistProviders: _s(json, 'assistProviders'),
          suggestedTemplate: effective,
        );
      case CardTemplate.onThisDay:
        return CardData.onThisDay(
          dateLabel: _s(json, 'dateLabel'),
          yearsAgo: _i(json, 'yearsAgo'),
          competition: _s(json, 'competition'),
          headline: _s(json, 'headline', sparseHeadline),
          keyStats: _list(
            json,
            'keyStats',
            (j) => StatItem(
              label: _s(j, 'label'),
              value: _s(j, 'value'),
              context: _s(j, 'context'),
            ),
          ),
          venue: _s(json, 'venue'),
          attendance: _s(json, 'attendance'),
          result: _s(json, 'result'),
          significance: _s(json, 'significance', sparseSubtext),
          suggestedTemplate: effective,
        );
      case CardTemplate.startingXI:
        return CardData.startingXI(
          teamName: _s(json, 'teamName'),
          formation: _s(json, 'formation'),
          starters: _list(
            json,
            'starters',
            (j) => LineupPlayer(
              number: _s(j, 'number'),
              name: _s(j, 'name', 'N/A'),
            ),
          ),
          subs: _list(
            json,
            'subs',
            (j) => LineupPlayer(
              number: _s(j, 'number'),
              name: _s(j, 'name', 'N/A'),
            ),
          ),
          manager: _s(json, 'manager'),
          averageAge: _s(json, 'averageAge'),
          keyAbsences: _s(json, 'keyAbsences'),
          captain: _s(json, 'captain'),
          viceCaptain: _s(json, 'viceCaptain'),
          tactics: _s(json, 'tactics'),
          injuredPlayers: _s(json, 'injuredPlayers'),
          suspendedPlayers: _s(json, 'suspendedPlayers'),
          suggestedTemplate: effective,
        );
      case CardTemplate.matchStatsComparison:
        return CardData.matchStatsComparison(
          homeTeam: _s(json, 'homeTeam'),
          awayTeam: _s(json, 'awayTeam'),
          stats: _list(
            json,
            'stats',
            (j) => ComparisonStat(
              label: _s(j, 'label'),
              homeValue: _s(j, 'homeValue'),
              awayValue: _s(j, 'awayValue'),
            ),
          ),
          suggestedTemplate: effective,
        );
      case CardTemplate.socialPost:
        return CardData.socialPost(
          handle: _s(json, 'handle'),
          name: _s(json, 'name'),
          content: _s(json, 'content', sparseHeadline),
          timestamp: _s(json, 'timestamp'),
          metrics: _s(json, 'metrics', sparseSubtext),
          verified: json['verified'] == true,
          followers: _s(json, 'followers'),
          shares: _s(json, 'shares'),
          bookmarks: _s(json, 'bookmarks'),
          mediaType: _s(json, 'mediaType'),
          isEdited: json['isEdited'] == true,
          suggestedTemplate: effective,
        );
      case CardTemplate.rivalry:
        return CardData.rivalry(
          player1Name: _s(json, 'player1Name'),
          player2Name: _s(json, 'player2Name'),
          matchContext: _s(json, 'matchContext'),
          player1Stats: stats3(
            json.containsKey('player1Stats')
                ? {'stats': json['player1Stats']}
                : json,
          ),
          player2Stats: _list(
            json,
            'player2Stats',
            (j) => StatItem(
              label: _s(j, 'label'),
              value: _s(j, 'value'),
              context: _s(j, 'context'),
            ),
          ),
          headToHead: _s(json, 'headToHead'),
          verdict: _s(json, 'verdict', sparseSubtext),
          compareType: _s(json, 'compareType'),
          totalMatches: _s(json, 'totalMatches'),
          draws: _s(json, 'draws'),
          player1Trophies: _s(json, 'player1Trophies'),
          player2Trophies: _s(json, 'player2Trophies'),
          predictionConfidence: _s(json, 'predictionConfidence'),
          suggestedTemplate: effective,
        );
      case CardTemplate.tableStandings:
        return CardData.tableStandings(
          leagueName: _s(json, 'leagueName', sparseHeadline),
          matchday: _s(json, 'matchday'),
          standings: _list(
            json,
            'standings',
            (j) => TableRow(
              position: _i(j, 'position'),
              teamName: _s(j, 'teamName'),
              played: _i(j, 'played'),
              won: _i(j, 'won'),
              drawn: _i(j, 'drawn'),
              lost: _i(j, 'lost'),
              points: _i(j, 'points'),
              form: _s(j, 'form'),
            ),
          ),
          highlightedTeam: _s(json, 'highlightedTeam'),
          promotionZone: _i(json, 'promotionZone', 4),
          relegationZone: _i(json, 'relegationZone', 18),
          gamesInHand: _s(json, 'gamesInHand'),
          pointsBehindLeader: _s(json, 'pointsBehindLeader'),
          topScorer: _s(json, 'topScorer'),
          topAssists: _s(json, 'topAssists'),
          suggestedTemplate: effective,
        );
      case CardTemplate.injuryReport:
        return CardData.injuryReport(
          teamName: _s(json, 'teamName'),
          reportDate: _s(json, 'reportDate'),
          injuries: _list(
            json,
            'injuries',
            (j) => InjuryItem(
              playerName: _s(j, 'playerName'),
              injury: _s(j, 'injury'),
              status: _s(j, 'status'),
              position: _s(j, 'position'),
              recoveryPercentage: _s(j, 'recoveryPercentage'),
              isLongTerm: j['isLongTerm'] == true,
              surgeryRequired: j['surgeryRequired'] == true,
            ),
          ),
          doubtfits: _list(
            json,
            'doubtfits',
            (j) => InjuryItem(
              playerName: _s(j, 'playerName'),
              injury: _s(j, 'injury'),
              status: _s(j, 'status'),
              position: _s(j, 'position'),
              recoveryPercentage: _s(j, 'recoveryPercentage'),
              isLongTerm: j['isLongTerm'] == true,
              surgeryRequired: j['surgeryRequired'] == true,
            ),
          ),
          returns: _list(
            json,
            'returns',
            (j) => InjuryItem(
              playerName: _s(j, 'playerName'),
              injury: _s(j, 'injury'),
              status: _s(j, 'status'),
              position: _s(j, 'position'),
              recoveryPercentage: _s(j, 'recoveryPercentage'),
              isLongTerm: j['isLongTerm'] == true,
              surgeryRequired: j['surgeryRequired'] == true,
            ),
          ),
          nextMatch: _s(json, 'nextMatch'),
          recoveryPercentage: _s(json, 'recoveryPercentage'),
          suggestedTemplate: effective,
        );
      case CardTemplate.contractExpiry:
        return CardData.contractExpiry(
          teamName: _s(json, 'teamName'),
          seasonYear: _s(json, 'seasonYear'),
          expiringPlayers: _list(
            json,
            'expiringPlayers',
            (j) => ContractPlayer(
              playerName: _s(j, 'playerName'),
              position: _s(j, 'position'),
              expiresIn: _s(j, 'expiresIn'),
              marketValue: _s(j, 'marketValue'),
              status: _s(j, 'status'),
              wage: _s(j, 'wage'),
              askingPrice: _s(j, 'askingPrice'),
              interestLevel: _s(j, 'interestLevel'),
              negotiationProgress: _s(j, 'negotiationProgress'),
              previousClub: _s(j, 'previousClub'),
            ),
          ),
          renewals: _list(
            json,
            'renewals',
            (j) => ContractPlayer(
              playerName: _s(j, 'playerName'),
              position: _s(j, 'position'),
              expiresIn: _s(j, 'expiresIn'),
              marketValue: _s(j, 'marketValue'),
              status: _s(j, 'status'),
              wage: _s(j, 'wage'),
              askingPrice: _s(j, 'askingPrice'),
              interestLevel: _s(j, 'interestLevel'),
              negotiationProgress: _s(j, 'negotiationProgress'),
              previousClub: _s(j, 'previousClub'),
            ),
          ),
          wage: _s(json, 'wage'),
          askingPrice: _s(json, 'askingPrice'),
          interestLevel: _s(json, 'interestLevel'),
          suggestedTemplate: effective,
        );

      case CardTemplate.awardNominee:
        return CardData.awardNominee(
          awardName: _s(json, 'awardName', sparseHeadline),
          category: _s(json, 'category'),
          nominees: _list(
            json,
            'nominees',
            (j) => NomineeItem(
              playerName: _s(j, 'playerName'),
              club: _s(j, 'club'),
              achievement: _s(j, 'achievement'),
              odds: _s(j, 'odds'),
              isFavorite: j['isFavorite'] == true,
              previousWinner: j['previousWinner'] == true,
              votes: _s(j, 'votes'),
            ),
          ),
          ceremonyDate: _s(json, 'ceremonyDate'),
          currentFavorite: _s(json, 'currentFavorite'),
          votingDeadline: _s(json, 'votingDeadline'),
          votingMethod: _s(json, 'votingMethod'),
          totalNominees: _i(json, 'totalNominees'),
          venue: _s(json, 'venue'),
          host: _s(json, 'host'),
          suggestedTemplate: effective,
        );
      case CardTemplate.freeform:
        return CardData.sparse(
          headline: _s(json, 'headline'),
          subtext: _s(json, 'subtext'),
          microStat: _s(json, 'microStat'),
          suggestedTemplate: effective,
        );
    }
  }
}
