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
    this.secondRow = HomeWidgetSecondRow.quota,
    this.lastPostSnippet = '',
    this.lastPostReactions,
    this.lastPostComments,
    this.lastPostShares,
    this.lastPostAt,
    this.bestSlotLabel = '',
    this.bestSlotDetail = '',
    this.bestSlotConfident = false,
    this.storyFailedCount = 0,
    this.draftTitle = '',
    this.weekPostCount = 0,
    this.quotaAverage,
    this.pagesJson = '[]',
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

  /// Mean requests per active day over the last week for the same model as the
  /// quota row. `null` hides the trend line.
  final int? quotaAverage;

  final String pageName;
  final bool pageConnected;
  final bool pageExpired;

  final HomeWidgetPalette palette;

  /// Which block the provider draws under the divider. Every block is always
  /// in the payload; the mode is a pure render decision.
  final HomeWidgetSecondRow secondRow;

  /// Newest published post that has cached engagement. Empty keys hide the
  /// engagement block.
  final String lastPostSnippet;
  final int? lastPostReactions;
  final int? lastPostComments;
  final int? lastPostShares;
  final DateTime? lastPostAt;

  /// Deterministic local suggestion from [BestTimeToPost]. Empty when there is
  /// not enough history to name a slot.
  final String bestSlotLabel;
  final String bestSlotDetail;
  final bool bestSlotConfident;

  final int storyFailedCount;
  final String draftTitle;
  final int weekPostCount;

  /// Per-Page next-up, so a widget can be configured to pin one Page. A single
  /// JSON string keeps every payload value a `String`.
  final String pagesJson;

  bool get hasQuota => quotaUsed != null && quotaBudget != null;

  bool get hasLastPost =>
      lastPostAt != null &&
      (lastPostReactions != null ||
          lastPostComments != null ||
          lastPostShares != null);

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
    HomeWidgetKeys.quotaAverage: quotaAverage == null ? '' : '$quotaAverage',
    HomeWidgetKeys.pageName: pageName,
    HomeWidgetKeys.pageConnected: pageConnected ? '1' : '0',
    HomeWidgetKeys.pageExpired: pageExpired ? '1' : '0',
    HomeWidgetKeys.surface: palette.surfaceHex,
    HomeWidgetKeys.onSurface: palette.onSurfaceHex,
    HomeWidgetKeys.muted: palette.mutedHex,
    HomeWidgetKeys.primary: palette.primaryHex,
    HomeWidgetKeys.secondRowMode: secondRow.wireName,
    HomeWidgetKeys.lastPostSnippet: lastPostSnippet,
    HomeWidgetKeys.lastPostReactions: _number(lastPostReactions),
    HomeWidgetKeys.lastPostComments: _number(lastPostComments),
    HomeWidgetKeys.lastPostShares: _number(lastPostShares),
    HomeWidgetKeys.lastPostAt: _epoch(lastPostAt),
    HomeWidgetKeys.bestSlotLabel: bestSlotLabel,
    HomeWidgetKeys.bestSlotDetail: bestSlotDetail,
    HomeWidgetKeys.bestSlotConfident: bestSlotConfident ? '1' : '0',
    HomeWidgetKeys.storyFailedCount: '$storyFailedCount',
    HomeWidgetKeys.draftTitle: draftTitle,
    HomeWidgetKeys.weekPostCount: '$weekPostCount',
    HomeWidgetKeys.pagesJson: pagesJson,
  };

  static String _epoch(DateTime? value) =>
      value == null ? '' : '${value.millisecondsSinceEpoch}';

  static String _number(int? value) => value == null ? '' : '$value';
}

/// One Facebook Page as far as the widget cares: an identity and a display
/// name. Keeps this domain model free of the data-layer `FacebookPage`.
class HomeWidgetPage {
  const HomeWidgetPage({required this.id, required this.name});

  final String id;
  final String name;
}

/// What the provider draws under the divider.
///
/// The payload always carries every block, so switching costs one push and no
/// data loss; the provider owns the fallback chain when a block is empty.
enum HomeWidgetSecondRow {
  quota('quota', 'Gemini quota'),
  engagement('engagement', 'Last post'),
  drafts('drafts', 'Drafts'),
  bestTime('bestTime', 'Best time');

  const HomeWidgetSecondRow(this.wireName, this.label);

  /// Stable identifier shared with the native provider. Never translate this.
  final String wireName;

  /// Human label for the settings sheet.
  final String label;

  static HomeWidgetSecondRow fromWire(String? value) {
    final normalized = (value ?? '').trim();
    for (final row in values) {
      if (row.wireName == normalized) return row;
    }
    return HomeWidgetSecondRow.quota;
  }
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
  static const String currentVersion = '2';

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
  static const String quotaAverage = 'quota_average';
  static const String pageName = 'page_name';
  static const String pageConnected = 'page_connected';
  static const String pageExpired = 'page_expired';
  static const String surface = 'theme_surface';
  static const String onSurface = 'theme_on_surface';
  static const String muted = 'theme_muted';
  static const String primary = 'theme_primary';
  static const String secondRowMode = 'second_row_mode';
  static const String lastPostSnippet = 'last_post_snippet';
  static const String lastPostReactions = 'last_post_reactions';
  static const String lastPostComments = 'last_post_comments';
  static const String lastPostShares = 'last_post_shares';
  static const String lastPostAt = 'last_post_at';
  static const String bestSlotLabel = 'best_slot_label';
  static const String bestSlotDetail = 'best_slot_detail';
  static const String bestSlotConfident = 'best_slot_confident';
  static const String storyFailedCount = 'story_failed_count';
  static const String draftTitle = 'draft_title';
  static const String weekPostCount = 'week_post_count';
  static const String pagesJson = 'pages_json';

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
    quotaAverage,
    pageName,
    pageConnected,
    pageExpired,
    surface,
    onSurface,
    muted,
    primary,
    secondRowMode,
    lastPostSnippet,
    lastPostReactions,
    lastPostComments,
    lastPostShares,
    lastPostAt,
    bestSlotLabel,
    bestSlotDetail,
    bestSlotConfident,
    storyFailedCount,
    draftTitle,
    weekPostCount,
    pagesJson,
  };
}
