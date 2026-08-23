/// Supported theme modes for the Oreamnos app.
/// Matches the Android app's three theme options plus system default.
enum AppThemeMode {
  light('Light'),
  dark('Dark'),
  deepBlue('Deep Blue'),
  system('System');

  const AppThemeMode(this.label);

  final String label;
}
