/// Shared football lexicon — English terms that must NOT be translated to Bahasa Malaysia.
///
/// Used by both CardPromptManager (16 schemas) and GenerationPromptManager (feed).
/// Source: project_context naimnajmios-socurate FootballOcrParser + CardPromptManager 34 terms.
abstract final class FootballLexicon {
  static const List<String> terms = [
    'Clean Sheet',
    'Offside',
    'Hat-trick',
    'Tackle',
    'Assist',
    'Playmaker',
    'Derby',
    'Comeback',
    'Winger',
    'Striker',
    'Midfielder',
    'Defender',
    'Full-back',
    'Center-back',
    'Goalkeeper',
    'Free-kick',
    'Penalty',
    'Corner Kicks',
    'VAR',
    'Counter-attack',
    'Pressing',
    'Cross',
    'Header',
    'Nutmeg',
    'Dribble',
    'Volley',
    'Bicycle Kick',
    'Man of the Match',
    'Golden Boot',
    'Pitch',
    'Box-to-box',
    'Sweeper',
    'Target Man',
    'False Nine',
    'High Press',
    'Through Ball',
    'Overhead Kick',
  ];

  static String get inlineList => terms.map((e) => "'$e'").join(', ');
}
