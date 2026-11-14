/// Snapshot of the data the Android home-screen widget renders.
///
/// Every value is serialized as a [String]. The plugin maps a Dart `int` that
/// does not fit a signed 32-bit value (for example an opaque ARGB colour) to a
/// `long` in SharedPreferences, so a typed key would make the native side
/// throw a `ClassCastException` on `getInt`. Strings keep the contract
/// predictable on both sides.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.updatedAt,
    required this.nextSnippet,
    required this.nextPage,
    required this.nextAt,
    required this.nextIsStory,
    required this.scheduledCount,
    required this.draftCount,
    required this.quotaModel,
    required this.quotaUsed,
    required this.quotaBudget,
    required this.quotaResetAt,
    required this.pageName,
    required this.pageConnected,
    required this.pageExpired,
    required this.palette,
  });

  /// When this snapshot was built. The widget shows it when data goes stale.
  final DateTime updatedAt;

  final String nextSnippet;
  final String nextPage;
  final DateTime? nextAt;
  final bool nextIsStory;
  final int scheduledCount;
  final int draftCount;

  /// `null` when no Gemini requests were recorded today, which hides the
  /// quota half of the widget instead of pretending "0 / 0".
  final String? quotaModel;
  final int? quotaUsed;
  final int? quotaBudget;
  final DateTime? quotaResetAt;

  final String pageName;
  final bool pageConnected;
  final bool pageExpired;

  final HomeWidgetPalette palette;

  bool get hasQuota => quotaUsed != null && quotaBudget != null;

  /// Whitelisted payload. Update [HomeWidgetKeys.all] alongside this map.
  Map<String, String> toMap() => {
    HomeWidgetKeys.version: HomeWidgetKeys.currentVersion,
    HomeWidgetKeys.updatedAt: '${updatedAt.millisecondsSinceEpoch}',
    HomeWidgetKeys.nextSnippet: nextSnippet,
    HomeWidgetKeys.nextPage: nextPage,
    HomeWidgetKeys.nextAt: _epoch(nextAt),
    HomeWidgetKeys.nextIsStory: nextIsStory ? '1' : '0',
    HomeWidgetKeys.scheduledCount: '$scheduledCount',
    HomeWidgetKeys.draftCount: '$draftCount',
    HomeWidgetKeys.quotaModel: quotaModel ?? '',
    HomeWidgetKeys.quotaUsed: quotaUsed == null ? '' : '$quotaUsed',
    HomeWidgetKeys.quotaBudget: quotaBudget == null ? '' : '$quotaBudget',
    HomeWidgetKeys.quotaResetAt: _epoch(quotaResetAt),
    HomeWidgetKeys.pageName: pageName,
    HomeWidgetKeys.pageConnected: pageConnected ? '1' : '0',
    HomeWidgetKeys.pageExpired: pageExpired ? '1' : '0',
    HomeWidgetKeys.surface: palette.surfaceHex,
    HomeWidgetKeys.onSurface: palette.onSurfaceHex,
    HomeWidgetKeys.muted: palette.mutedHex,
    HomeWidgetKeys.primary: palette.primaryHex,
  };

  static String _epoch(DateTime? value) =>
      value == null ? '' : '${value.millisecondsSinceEpoch}';
}

/// Colours mirrored from the active app theme so the widget does not look
/// bolted on. Values are opaque ARGB ints.
class HomeWidgetPalette {
  const HomeWidgetPalette({
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.primary,
  });

  final int surface;
  final int onSurface;
  final int muted;
  final int primary;

  String get surfaceHex => _argb(surface);
  String get onSurfaceHex => _argb(onSurface);
  String get mutedHex => _argb(muted);
  String get primaryHex => _argb(primary);

  static String _argb(int value) =>
      '#${(value & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

/// SharedPreferences keys written through `home_widget`.
abstract final class HomeWidgetKeys {
  static const String currentVersion = '1';

  static const String version = 'widget_version';
  static const String updatedAt = 'updated_at';
  static const String nextSnippet = 'next_snippet';
  static const String nextPage = 'next_page';
  static const String nextAt = 'next_at';
  static const String nextIsStory = 'next_is_story';
  static const String scheduledCount = 'scheduled_count';
  static const String draftCount = 'draft_count';
  static const String quotaModel = 'quota_model';
  static const String quotaUsed = 'quota_used';
  static const String quotaBudget = 'quota_budget';
  static const String quotaResetAt = 'quota_reset_at';
  static const String pageName = 'page_name';
  static const String pageConnected = 'page_connected';
  static const String pageExpired = 'page_expired';
  static const String surface = 'theme_surface';
  static const String onSurface = 'theme_on_surface';
  static const String muted = 'theme_muted';
  static const String primary = 'theme_primary';

  /// Guard rail against accidentally pushing a token or permalink to a
  /// home-screen surface: the snapshot test asserts the payload only ever
  /// contains these keys.
  static const Set<String> all = {
    version,
    updatedAt,
    nextSnippet,
    nextPage,
    nextAt,
    nextIsStory,
    scheduledCount,
    draftCount,
    quotaModel,
    quotaUsed,
    quotaBudget,
    quotaResetAt,
    pageName,
    pageConnected,
    pageExpired,
    surface,
    onSurface,
    muted,
    primary,
  };
}
