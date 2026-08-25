import '../../domain/models/card_brief.dart';
import '../models/card_template.dart';

class CardPromptManager {
  // Updated per Phase B — CRITICAL RULE 3 now uses N/A (user preference), RULE 4 is template_intent
  static String buildSystemPrompt() {
    return '''You are a structured data extractor for football (soccer) companion visuals.
Your ONLY output must be a single valid JSON object.
Do NOT include any explanation, preamble, markdown, code fences, or text outside the JSON.
Start your response with { and end it with }.
CRITICAL RULE 1: Translate ALL extracted text values into Malaysian Malay (Bahasa Malaysia) EXCEPT for proper nouns like player names, club names, or tournament acronyms.
CRITICAL RULE 2: ALWAYS use these accepted English football terms instead of making up stiff direct translations in Bahasa Malaysia. Do NOT translate:
'Clean Sheet', 'Offside', 'Hat-trick', 'Tackle', 'Assist', 'Playmaker', 'Derby', 'Comeback', 'Winger', 'Striker', 'Midfielder', 'Defender', 'Full-back', 'Center-back', 'Goalkeeper', 'Free-kick', 'Penalty', 'Corner Kicks', 'VAR', 'Counter-attack', 'Pressing', 'Cross', 'Header', 'Nutmeg', 'Dribble', 'Volley', 'Bicycle Kick', 'Man of the Match', 'Golden Boot', 'Pitch', 'Box-to-box', 'Sweeper', 'Target Man', 'False Nine', 'High Press', 'Through Ball', 'Overhead Kick'.
CRITICAL RULE 3: If a specific piece of information is NOT explicitly mentioned, return "N/A" for that field. Do NOT guess or use placeholders like "", "-", "—". Use "N/A" consistently.
CRITICAL RULE 4: ALWAYS include "template_intent" field with one of: player_spotlight, headline_quote, top_stats, transfer_news, breaking_news, match_preview, detailed_scoreboard, on_this_day, starting_xi, match_stats_comparison, social_post, rivalry, table_standings, injury_report, contract_expiry, award_nominee. This helps auto-suggest the best template.''';
  }

  // Legacy sparse wrapper — now delegates to 16-template dispatch with SocialPost fallback
  static String buildUserPrompt(CardBrief brief) {
    return buildPrompt(CardTemplate.socialPost, brief.promptContext, false);
  }

  static String buildPrompt(CardTemplate template, String articleText, bool isRefresh) {
    final refreshTag = isRefresh ? '\n[Refresh ${DateTime.now().millisecondsSinceEpoch}]' : '';
    final schema = _schemaFor(template);
    final context = articleText.trim().isEmpty ? '(empty)' : articleText.trim();
    return '$schema\n\nINPUT:\n$context$refreshTag\n\nRespond with ONLY the JSON object, starting with {';
  }

  static String buildUserPromptForTemplate(dynamic template, String generatedText) {
    final CardTemplate t = template is CardTemplate ? template : CardTemplate.socialPost;
    return buildPrompt(t, generatedText, false);
  }

  static String _schemaFor(CardTemplate t) {
    switch (t) {
      case CardTemplate.playerSpotlight:
        return '''Extract Player Spotlight. Return ONLY JSON:
{
  "playerName": "Nama pemain",
  "club": "Kelab",
  "position": "Posisi (Striker etc)",
  "rating": 8.5,
  "goals": 2,
  "assists": 1,
  "minutesPlayed": 90,
  "keyAction": "Hat-trick / Clean Sheet etc atau N/A",
  "keyQuote": "Quote ringkas atau N/A",
  "nationality": "N/A",
  "appearances": 0,
  "cleanSheets": 0,
  "passes": 0,
  "tackles": 0,
  "template_intent": "player_spotlight"
}''';
      case CardTemplate.headlineQuote:
        return '''Extract Headline Quote. Return ONLY JSON:
{
  "headline": "Tajuk padat ≤60 aksara",
  "subtext": "Quote atau hook satu ayat ≤90 aksara",
  "quoteAuthor": "Nama penutur atau N/A",
  "authorTitle": "Jawatan / kelab atau N/A",
  "category": "Kategori atau N/A",
  "relatedTeams": "Pasukan berkaitan atau N/A",
  "template_intent": "headline_quote"
}''';
      case CardTemplate.topStats:
        return '''Extract Top 3 Stats. Return ONLY JSON:
{
  "matchContext": "Konteks perlawanan atau N/A",
  "stats": [
    {"label": "Gol", "value": "2", "context": "N/A"},
    {"label": "Assist", "value": "1", "context": "N/A"},
    {"label": "Clean Sheet", "value": "1", "context": "N/A"}
  ],
  "template_intent": "top_stats"
}''';
      case CardTemplate.transferNews:
        return '''Extract Transfer News. Return ONLY JSON:
{
  "playerName": "Nama pemain",
  "action": "SAH / DIPINJAM / SELESAI / KHABAR ANGIN",
  "fromTeam": "Pasukan asal atau N/A",
  "toTeam": "Pasukan destinasi atau N/A",
  "fee": "Yuran atau N/A",
  "contractLength": "Tempoh kontrak atau N/A",
  "transferType": "Jenis perpindahan atau N/A",
  "quote": "Quote atau N/A",
  "feeCategory": "N/A",
  "medicalCompleted": false,
  "workPermit": false,
  "agentName": "N/A",
  "template_intent": "transfer_news"
}''';
      case CardTemplate.breakingNews:
        return '''Extract Breaking News. Return ONLY JSON:
{
  "label": "🚨 BREAKING",
  "headline": "Tajuk tergempar ≤60 aksara",
  "subtext": "Ringkasan satu ayat atau N/A",
  "impactRating": 3,
  "relatedTeams": "Pasukan berkaitan atau N/A",
  "template_intent": "breaking_news"
}''';
      case CardTemplate.matchPreview:
        return '''Extract Match Preview. Return ONLY JSON:
{
  "competition": "Liga / Kejohanan atau N/A",
  "homeTeam": "Tuan rumah",
  "awayTeam": "Pelawat",
  "homeForm": "Form atau N/A",
  "awayForm": "Form atau N/A",
  "matchTime": "Tarikh/masa atau N/A",
  "stadium": "Stadium atau N/A",
  "referee": "N/A",
  "tvChannel": "N/A",
  "kickoffTime": "N/A",
  "weather": "N/A",
  "capacity": "N/A",
  "template_intent": "match_preview"
}''';
      case CardTemplate.detailedScoreboard:
        return '''Extract Detailed Scoreboard. Return ONLY JSON:
{
  "homeTeam": "Tuan rumah",
  "awayTeam": "Pelawat",
  "homeScore": 2,
  "awayScore": 1,
  "homeScorers": "Penjaring atau N/A",
  "awayScorers": "Penjaring atau N/A",
  "possession": "N/A",
  "shotsOnTarget": "N/A",
  "competition": "N/A",
  "matchStatus": "FT / HT atau N/A",
  "corners": "N/A",
  "fouls": "N/A",
  "yellowCards": "N/A",
  "redCards": "N/A",
  "attendance": "N/A",
  "referee": "N/A",
  "penaltyShootout": "N/A",
  "assistProviders": "N/A",
  "template_intent": "detailed_scoreboard"
}''';
      case CardTemplate.onThisDay:
        return '''Extract On This Day. Return ONLY JSON:
{
  "dateLabel": "Tarikh atau N/A",
  "yearsAgo": 10,
  "competition": "N/A",
  "headline": "Tajuk peristiwa atau N/A",
  "keyStats": [{"label": "Gol", "value": "3", "context": "N/A"}],
  "venue": "N/A",
  "attendance": "N/A",
  "result": "N/A",
  "significance": "N/A",
  "template_intent": "on_this_day"
}''';
      case CardTemplate.startingXI:
        return '''Extract Starting XI. Return ONLY JSON:
{
  "teamName": "Pasukan atau N/A",
  "formation": "4-3-3 atau N/A",
  "starters": [{"number": "10", "name": "Nama"}],
  "subs": [{"number": "9", "name": "Nama"}],
  "manager": "N/A",
  "averageAge": "N/A",
  "keyAbsences": "N/A",
  "captain": "N/A",
  "viceCaptain": "N/A",
  "tactics": "N/A",
  "injuredPlayers": "N/A",
  "suspendedPlayers": "N/A",
  "template_intent": "starting_xi"
}''';
      case CardTemplate.matchStatsComparison:
        return '''Extract Match Stats Comparison. Return ONLY JSON:
{
  "homeTeam": "Tuan rumah atau N/A",
  "awayTeam": "Pelawat atau N/A",
  "stats": [{"label": "Possession", "homeValue": "55%", "awayValue": "45%"}],
  "template_intent": "match_stats_comparison"
}''';
      case CardTemplate.socialPost:
        return '''Extract Social Post (sparse companion). Return ONLY JSON:
{
  "handle": "@handle atau N/A",
  "name": "Nama atau N/A",
  "content": "Kandungan padat",
  "timestamp": "N/A",
  "metrics": "N/A",
  "verified": false,
  "followers": "N/A",
  "shares": "N/A",
  "bookmarks": "N/A",
  "mediaType": "N/A",
  "isEdited": false,
  "template_intent": "social_post"
}''';
      case CardTemplate.rivalry:
        return '''Extract Rivalry. Return ONLY JSON:
{
  "player1Name": "N/A",
  "player2Name": "N/A",
  "matchContext": "N/A",
  "player1Stats": [{"label": "Gol", "value": "10", "context": "N/A"}],
  "player2Stats": [{"label": "Gol", "value": "8", "context": "N/A"}],
  "headToHead": "N/A",
  "verdict": "N/A",
  "compareType": "N/A",
  "totalMatches": "N/A",
  "draws": "N/A",
  "player1Trophies": "N/A",
  "player2Trophies": "N/A",
  "predictionConfidence": "N/A",
  "template_intent": "rivalry"
}''';
      case CardTemplate.tableStandings:
        return '''Extract League Table. Return ONLY JSON:
{
  "leagueName": "Liga atau N/A",
  "matchday": "N/A",
  "standings": [
    {"position": 1, "teamName": "Pasukan A", "played": 10, "won": 7, "drawn": 2, "lost": 1, "points": 23, "form": "N/A"}
  ],
  "highlightedTeam": "N/A",
  "promotionZone": 4,
  "relegationZone": 18,
  "gamesInHand": "N/A",
  "pointsBehindLeader": "N/A",
  "topScorer": "N/A",
  "topAssists": "N/A",
  "template_intent": "table_standings"
}''';
      case CardTemplate.injuryReport:
        return '''Extract Injury Report. Return ONLY JSON:
{
  "teamName": "Pasukan atau N/A",
  "reportDate": "N/A",
  "injuries": [{"playerName": "Nama", "injury": "Kecederaan", "status": "Out", "position": "N/A", "recoveryPercentage": "N/A", "isLongTerm": false, "surgeryRequired": false}],
  "doubtfits": [],
  "returns": [],
  "nextMatch": "N/A",
  "recoveryPercentage": "N/A",
  "template_intent": "injury_report"
}''';
      case CardTemplate.contractExpiry:
        return '''Extract Contract Expiry. Return ONLY JSON:
{
  "teamName": "Pasukan atau N/A",
  "seasonYear": "N/A",
  "expiringPlayers": [{"playerName": "Nama", "position": "N/A", "expiresIn": "N/A", "marketValue": "N/A", "status": "N/A", "wage": "N/A", "askingPrice": "N/A", "interestLevel": "N/A", "negotiationProgress": "N/A", "previousClub": "N/A"}],
  "renewals": [],
  "wage": "N/A",
  "askingPrice": "N/A",
  "interestLevel": "N/A",
  "template_intent": "contract_expiry"
}''';
      case CardTemplate.awardNominee:
        return '''Extract Award Nominees. Return ONLY JSON:
{
  "awardName": "Anugerah atau N/A",
  "category": "N/A",
  "nominees": [{"playerName": "Nama", "club": "Kelab", "achievement": "Pencapaian", "odds": "N/A", "isFavorite": false, "previousWinner": false, "votes": "N/A"}],
  "ceremonyDate": "N/A",
  "currentFavorite": "N/A",
  "votingDeadline": "N/A",
  "votingMethod": "N/A",
  "totalNominees": 0,
  "venue": "N/A",
  "host": "N/A",
  "template_intent": "award_nominee"
}''';
    }
  }

  // ignore: unused_element
  static String _sparseSchema() {
    return '''
Polish the INPUT into a lightweight social companion card.
Return ONLY a JSON object with this exact structure (write values in Bahasa Malaysia per rules, use "N/A" for missing):
{
  "headline": "Tajuk hook padat (maks 60 aksara, UPPERCASE-ready)",
  "subtext": "Satu ayat umpan ringan (maks 90 aksara, satu ayat sahaja)",
  "microStat": "Satu badge ringkas (maks 24 aksara) atau N/A jika tiada"
}''';
  }
}

