/// Supported theme modes for the Oreamnos app.
enum AppThemeMode {
  system('System'),
  voidMode('Void'),
  flashMode('Flash');

  const AppThemeMode(this.label);

  final String label;

  static AppThemeMode fromString(String? value) {
    if (value == null) return AppThemeMode.system;
    // Map legacy names to new equivalents to prevent crashing on existing installs
    if (value == 'light' || value == 'solarizedLight' || value == 'matchday') {
      return AppThemeMode.flashMode;
    }
    if (value == 'dark' || value == 'deepBlue' || value == 'midnightNoir' || value == 'cyberpunk' || value == 'forest') {
      return AppThemeMode.voidMode;
    }
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}
