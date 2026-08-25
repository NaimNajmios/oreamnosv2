/// Supported theme modes for the Oreamnos app.
/// Matches the Android app's three theme options plus system default.
enum AppThemeMode {
  light('Light'),
  dark('Dark'),
  deepBlue('Deep Blue'),
  midnightNoir('Midnight Noir'),
  solarizedLight('Solarized Light'),
  cyberpunk('Cyberpunk'),
  matchday('Matchday'),
  forest('Forest'),
  system('System');

  const AppThemeMode(this.label);

  final String label;
}
