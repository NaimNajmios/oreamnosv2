import '../../ui/features/card_generator/view_models/card_generator_view_model.dart';

class CardPromptManager {
  static String buildSystemPrompt() {
    return '''You are a structured data extractor for football (soccer) articles.
Your ONLY output must be a single valid JSON object.
Do NOT include any explanation, preamble, markdown, code fences, or text outside the JSON.
Start your response with { and end it with }.
CRITICAL RULE 1: Translate ALL extracted text values into Malaysian Malay (Bahasa Malaysia) EXCEPT for proper nouns like player names, club names, or tournament acronyms.
CRITICAL RULE 2: ALWAYS use these accepted English football terms instead of making up stiff direct translations in Bahasa Malaysia. Do NOT translate:
'Clean Sheet', 'Offside', 'Hat-trick', 'Tackle', 'Assist', 'Playmaker', 'Derby', 'Comeback', 'Winger', 'Striker', 'Midfielder', 'Defender', 'Full-back', 'Center-back', 'Goalkeeper', 'Free-kick', 'Penalty', 'Corner Kicks', 'VAR', 'Counter-attack', 'Pressing', 'Cross', 'Header', 'Nutmeg', 'Dribble', 'Volley', 'Bicycle Kick', 'Man of the Match', 'Golden Boot', 'Pitch', 'Box-to-box', 'Sweeper', 'Target Man', 'False Nine', 'High Press', 'Through Ball', 'Overhead Kick'.
CRITICAL RULE 3: If a specific piece of information (e.g., stats, dates, fees) is NOT explicitly mentioned in the text, you MUST return an empty string "" or 0 for numeric fields. Do NOT guess, infer, or provide placeholders like 'N/A', '-', or '—'.''';
  }

  static String buildUserPrompt(CardTemplate template, String generatedText) {
    final schema = _getSchemaForTemplate(template);
    return '\$schema\n\nARTICLE:\n\$generatedText\n\nRespond with ONLY the JSON object, starting with {';
  }

  static String _getSchemaForTemplate(CardTemplate template) {
    switch (template) {
      case CardTemplate.playerSpotlight:
        return '''
Extract the standout player's data from the football article below.
IMPORTANT: Use empty string "" for any field that is not explicitly mentioned in the article. Do NOT guess or infer values.
Return ONLY a JSON object with this exact structure (fill in real values, write descriptions in Bahasa Malaysia):
{
  "playerName": "Full Name",
  "club": "Club Name",
  "position": "Posisi Pemain (Bahasa Melayu)",
  "rating": 7.5,
  "goals": 0,
  "assists": 0,
  "minutesPlayed": 90,
  "keyAction": "Satu frasa pendek (maks 3 patah perkataan, e.g. Wira Hat-Trick)",
  "keyQuote": "Satu ayat menerangkan prestasi pemain tersebut (maks 100 aksara)"
}''';
      case CardTemplate.headlineQuote:
        return '''
Extract the single most impactful headline or quote from the football article below.
IMPORTANT: Use empty string "" for any field that is not explicitly mentioned in the article. Do NOT guess or infer values.
Return ONLY a JSON object with this exact structure (fill in real values, write descriptions in Bahasa Malaysia):
{
  "headline": "Tajuk utama atau petikan paling penting (maks 120 aksara)",
  "subtext": "Satu perenggan sokongan ringkas (maks 60 aksara)",
  "quoteAuthor": "Nama penutur (biarkan kosong jika bukan petikan)",
  "authorTitle": "Jawatan (e.g. Manager, CEO)"
}''';
      case CardTemplate.topStats:
        return '''
Extract the 3 most interesting statistics from the football article below.
Return ONLY a JSON object with this exact structure:
{
  "matchContext": "Perlawanan atau kejohanan yang berkaitan",
  "stats": [
    { "label": "Nama stat (maks 30 aksara)", "value": "Nilai nombor", "context": "Konteks ringkas" }
  ]
}''';
      case CardTemplate.transferNews:
        return '''
Extract the transfer news or rumors from the football article below.
Return ONLY a JSON object with this exact structure:
{
  "playerName": "Full Name",
  "action": "Status (MUST BE ONE OF: SAH, DIPINJAM, SELESAI, KHABAR_ANGIN)",
  "fromTeam": "Pasukan Asal",
  "toTeam": "Pasukan Baru",
  "fee": "Yuran Perpindahan",
  "contractLength": "Tempoh Kontrak (e.g. 5 Tahun)",
  "transferType": "Jenis (e.g. Tetap, Pinjaman, Percuma)"
}''';
      case CardTemplate.breakingNews:
        return '''
Extract the breaking or urgent news from the football article below.
Return ONLY a JSON object with this exact structure:
{
  "label": "Label Berita (e.g. [URGEN], [RASMI], [EKSKLUSIF])",
  "headline": "Tajuk berita utama (maks 100 aksara)",
  "subtext": "Satu atau dua ayat menerangkan konteks (maks 150 aksara)"
}''';
      case CardTemplate.detailedScoreboard:
      case CardTemplate.matchPreview:
      case CardTemplate.onThisDay:
      case CardTemplate.startingXI:
      case CardTemplate.matchStatsComparison:
      case CardTemplate.socialPost:
      case CardTemplate.rivalry:
      case CardTemplate.tableStandings:
      case CardTemplate.injuryReport:
      case CardTemplate.contractExpiry:
      case CardTemplate.awardNominee:
      default:
        // Generic fallback to headline for omitted templates in this iteration
        return '''
Extract the main information from the football article below.
Return ONLY a JSON object with this exact structure:
{
  "title": "Tajuk utama",
  "subtitle": "Konteks ringkas",
  "keyPoints": ["Point 1", "Point 2"]
}''';
    }
  }
}

