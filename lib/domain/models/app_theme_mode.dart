/// Supported theme modes for the Oreamnos app.
enum AppThemeMode {
  system('System'),
  dark('Dark'),
  light('Light');

  const AppThemeMode(this.label);

  final String label;

  static AppThemeMode fromString(String? value) {
    if (value == null) return AppThemeMode.system;
    // Map legacy names to new equivalents to prevent crashing on existing installs
    if (value == 'light' || value == 'solarizedLight' || value == 'matchday' || value == 'flashMode') {
      return AppThemeMode.light;
    }
    if (value == 'dark' || value == 'deepBlue' || value == 'midnightNoir' || value == 'cyberpunk' || value == 'forest' || value == 'voidMode') {
      return AppThemeMode.dark;
    }
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}
