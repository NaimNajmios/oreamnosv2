/// Supported theme modes for the Oreamnos app.
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

  static AppThemeMode fromString(String? value) {
    if (value == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}


