/// Graph metric names live here so a Meta rename is a one-file change.
///
/// Meta retired several post/page metrics on 15 June 2026. The names below
/// are the current replacements; confirm them in Graph Explorer before
/// shipping a new Graph version, and keep parsing tolerant of missing
/// metrics (a missing value is `null`, never `0`).
abstract final class FacebookMetricNames {
  // Post-level (insights.metric(...)).
  static const String postTotalMediaViewUnique = 'post_total_media_view_unique';
  static const String postReactionsByTypeTotal = 'post_reactions_by_type_total';
  static const String postActivityByActionType = 'post_activity_by_action_type';

  // Page-level (/{page-id}/insights).
  static const String pageMediaView = 'page_media_view';
  static const String pageFollows = 'page_follows';
  static const String pagePostEngagements = 'page_post_engagements';

  // Monetization (Content Monetization Pages).
  static const String contentMonetizationEarnings =
      'content_monetization_earnings';
  static const String monetizationApproximateEarnings =
      'monetization_approximate_earnings';

  /// Retired metrics that may still appear in older cached payloads. Never
  /// request these.
  static const Set<String> retiredPostMetrics = {
    'post_impressions',
    'post_impressions_unique',
    'post_engaged_users',
    'post_negative_feedback',
    'post_clicks',
  };
}
