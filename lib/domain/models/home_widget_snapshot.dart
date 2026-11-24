import 'dart:convert';

/// Snapshot of the data the Android home-screen widgets render.
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
    required this.quotaJson,
    required this.pageName,
    required this.pageConnected,
    required this.pageExpired,
    required this.palette,
    required this.activeProvider,
    required this.fallbackProvider,
    this.lastPostSnippet = '',
    this.lastPostReactions,
    this.lastPostComments,
    this.lastPostShares,
    this.lastPostImpressions,
    this.lastPostUniqueViewers,
    this.lastPostAt,
    this.weekReactions = 0,
    this.weekComments = 0,
    this.weekShares = 0,
    this.bestSlotLabel = '',
    this.bestSlotDetail = '',
    this.bestSlotConfident = false,
    this.bestSlotNextAt,
    this.bestSlotSamples = 0,
    this.storyFailedCount = 0,
    this.draftTitle = '',
    this.draftTitlesJson = '[]',
    this.draftUpdatedAt,
    this.weekPostCount = 0,
    this.pagesJson = '[]',
    this.quotaResetAt,
  });

  /// When this snapshot was built. The widget shows it when data goes stale.
  final DateTime updatedAt;

  final String nextSnippet;
  final String nextPage;
  final DateTime? nextAt;
  final bool nextIsStory;
  final int scheduledCount;
  final int draftCount;

  /// Every provider's daily request count, as a compact JSON array. The quota
  /// widget picks two of them from its own per-widget config, so one payload
  /// serves every placed widget. See [HomeWidgetQuota.toJson].
  final String quotaJson;

  /// Gemini's Pacific reset instant. Not sent to the widgets — it only drives
  /// the scheduled refresh alarm — because each provider's reset time already
  /// travels inside [quotaJson].
  final DateTime? quotaResetAt;

  final String pageName;
  final bool pageConnected;
  final bool pageExpired;

  final HomeWidgetPalette palette;

  /// The app's selected provider and its rate-limit fallback. The quota
  /// widget uses them as its default pair; the user can override each slot.
  final String activeProvider;
  final String fallbackProvider;

  /// Newest published post that has cached engagement. Empty keys hide the
  /// engagement widget's metrics.
  final String lastPostSnippet;
  final int? lastPostReactions;
  final int? lastPostComments;
  final int? lastPostShares;
  final int? lastPostImpressions;
  final int? lastPostUniqueViewers;
  final DateTime? lastPostAt;

  /// Totals across the published posts of the current week.
  final int weekReactions;
  final int weekComments;
  final int weekShares;

  /// Deterministic local suggestion from `BestTimeToPost`. Empty when there is
  /// not enough history to name a slot.
  final String bestSlotLabel;
  final String bestSlotDetail;
  final bool bestSlotConfident;

  /// Next local occurrence of the suggested slot and the number of posts that
  /// back it. The clock motif renders these instead of inventing a time.
  final DateTime? bestSlotNextAt;
  final int bestSlotSamples;

  final int storyFailedCount;
  final String draftTitle;

  /// Up to two newest draft titles, encoded once so the drafts widget can
  /// offer a continuation target without shipping the whole store.
  final String draftTitlesJson;

  final DateTime? draftUpdatedAt;
  final int weekPostCount;

  /// Per-Page next-up, so a widget can be configured to pin one Page. A single
  /// JSON string keeps every payload value a `String`.
  final String pagesJson;

  bool get hasLastPost =>
      lastPostAt != null &&
      (lastPostReactions != null ||
          lastPostComments != null ||
          lastPostShares != null ||
          lastPostImpressions != null ||
          lastPostUniqueViewers != null);

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
    HomeWidgetKeys.quotaJson: quotaJson,
    HomeWidgetKeys.pageName: pageName,
    HomeWidgetKeys.pageConnected: pageConnected ? '1' : '0',
    HomeWidgetKeys.pageExpired: pageExpired ? '1' : '0',
    HomeWidgetKeys.surface: palette.surfaceHex,
    HomeWidgetKeys.onSurface: palette.onSurfaceHex,
    HomeWidgetKeys.muted: palette.mutedHex,
    HomeWidgetKeys.primary: palette.primaryHex,
    HomeWidgetKeys.activeProvider: activeProvider,
    HomeWidgetKeys.fallbackProvider: fallbackProvider,
    HomeWidgetKeys.lastPostSnippet: lastPostSnippet,
    HomeWidgetKeys.lastPostReactions: _number(lastPostReactions),
    HomeWidgetKeys.lastPostComments: _number(lastPostComments),
    HomeWidgetKeys.lastPostShares: _number(lastPostShares),
    HomeWidgetKeys.lastPostImpressions: _number(lastPostImpressions),
    HomeWidgetKeys.lastPostUniqueViewers: _number(lastPostUniqueViewers),
    HomeWidgetKeys.lastPostAt: _epoch(lastPostAt),
    HomeWidgetKeys.weekReactions: '$weekReactions',
    HomeWidgetKeys.weekComments: '$weekComments',
    HomeWidgetKeys.weekShares: '$weekShares',
    HomeWidgetKeys.bestSlotLabel: bestSlotLabel,
    HomeWidgetKeys.bestSlotDetail: bestSlotDetail,
    HomeWidgetKeys.bestSlotConfident: bestSlotConfident ? '1' : '0',
    HomeWidgetKeys.bestSlotNextAt: _epoch(bestSlotNextAt),
    HomeWidgetKeys.bestSlotSamples: '$bestSlotSamples',
    HomeWidgetKeys.storyFailedCount: '$storyFailedCount',
    HomeWidgetKeys.draftTitle: draftTitle,
    HomeWidgetKeys.draftTitlesJson: draftTitlesJson,
    HomeWidgetKeys.draftUpdatedAt: _epoch(draftUpdatedAt),
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

/// Today's request count for one AI provider.
///
/// [budget] is only non-null when the app actually knows a daily limit (the
/// Gemini free tier). The quota widget must never imply a limit it does not
/// have, so an absent budget renders a count instead of a ring.
class HomeWidgetQuota {
  const HomeWidgetQuota({
    required this.providerId,
    required this.displayName,
    required this.modelId,
    required this.requestsToday,
    this.budget,
    this.average,
    this.resetAt,
  });

  /// Lower-case provider id, matching `AiProvider.name` and the key stored by
  /// `DailyUsageService` (`gemini`, `groq`, `openrouter`, `cerebras`).
  final String providerId;
  final String displayName;

  /// Short model label (`2.5 Flash`), empty when nothing ran today.
  final String modelId;
  final int requestsToday;
  final int? budget;

  /// Mean requests per active day over the retained week.
  final int? average;
  final DateTime? resetAt;

  bool get hasBudget => budget != null && budget! > 0;

  /// Severity bucket 0 = ok, 1 = warn, 2 = at/over budget.
  ///
  /// Computed on the Dart side so the native renderer never re-derives a
  /// business rule, and so the threshold stays aligned with the Usage screen.
  int severity(double warnFraction) {
    if (!hasBudget) return 0;
    if (requestsToday >= budget!) return 2;
    return requestsToday >= (budget! * warnFraction).ceil() ? 1 : 0;
  }

  /// Compact wire form. Short keys keep the whole array inside
  /// `HomeWidgetSnapshotBuilder.maxQuotaJsonChars`.
  ///
  /// `p` provider id · `n` display name · `m` model · `u` used · `b` budget ·
  /// `pc` percent · `s` severity · `r` reset epoch · `a` average.
  Map<String, Object> toJson(double warnFraction) => {
    'p': providerId,
    'n': displayName,
    'm': modelId,
    'u': requestsToday,
    if (hasBudget) ...{
      'b': budget!,
      'pc': ((requestsToday * 100) / budget!).clamp(0, 100).round(),
      's': severity(warnFraction),
    },
    'a': ?average,
    if (resetAt != null) 'r': resetAt!.millisecondsSinceEpoch,
  };

  static String encodeAll(List<HomeWidgetQuota> quotas, double warnFraction) =>
      jsonEncode([for (final quota in quotas) quota.toJson(warnFraction)]);
}

/// Colours mirrored from the active app theme so the widgets do not look
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
  static const String currentVersion = '4';

  static const String version = 'widget_version';
  static const String updatedAt = 'updated_at';
  static const String nextSnippet = 'next_snippet';
  static const String nextPage = 'next_page';
  static const String nextAt = 'next_at';
  static const String nextIsStory = 'next_is_story';
  static const String scheduledCount = 'scheduled_count';
  static const String draftCount = 'draft_count';
  static const String quotaJson = 'quota_json';
  static const String pageName = 'page_name';
  static const String pageConnected = 'page_connected';
  static const String pageExpired = 'page_expired';
  static const String surface = 'theme_surface';
  static const String onSurface = 'theme_on_surface';
  static const String muted = 'theme_muted';
  static const String primary = 'theme_primary';
  static const String activeProvider = 'active_provider';
  static const String fallbackProvider = 'fallback_provider';
  static const String lastPostSnippet = 'last_post_snippet';
  static const String lastPostReactions = 'last_post_reactions';
  static const String lastPostComments = 'last_post_comments';
  static const String lastPostShares = 'last_post_shares';
  static const String lastPostImpressions = 'last_post_impressions';
  static const String lastPostUniqueViewers = 'last_post_unique_viewers';
  static const String lastPostAt = 'last_post_at';
  static const String weekReactions = 'week_reactions';
  static const String weekComments = 'week_comments';
  static const String weekShares = 'week_shares';
  static const String bestSlotLabel = 'best_slot_label';
  static const String bestSlotDetail = 'best_slot_detail';
  static const String bestSlotConfident = 'best_slot_confident';
  static const String bestSlotNextAt = 'best_slot_next_at';
  static const String bestSlotSamples = 'best_slot_samples';
  static const String storyFailedCount = 'story_failed_count';
  static const String draftTitle = 'draft_title';
  static const String draftTitlesJson = 'draft_titles_json';
  static const String draftUpdatedAt = 'draft_updated_at';
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
    quotaJson,
    pageName,
    pageConnected,
    pageExpired,
    surface,
    onSurface,
    muted,
    primary,
    activeProvider,
    fallbackProvider,
    lastPostSnippet,
    lastPostReactions,
    lastPostComments,
    lastPostShares,
    lastPostImpressions,
    lastPostUniqueViewers,
    lastPostAt,
    weekReactions,
    weekComments,
    weekShares,
    bestSlotLabel,
    bestSlotDetail,
    bestSlotConfident,
    bestSlotNextAt,
    bestSlotSamples,
    storyFailedCount,
    draftTitle,
    draftTitlesJson,
    draftUpdatedAt,
    weekPostCount,
    pagesJson,
  };
}
