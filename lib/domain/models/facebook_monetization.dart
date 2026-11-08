/// Estimated Content Monetization earnings for a period.
///
/// Values are restated by Meta and payouts differ because of reviews and
/// copyright claims. A zero can also mean "not enrolled", so the UI must
/// never say "no earnings" from this alone.
class FacebookMonetizationSnapshot {
  const FacebookMonetizationSnapshot({
    required this.pageId,
    required this.totalEarnings,
    required this.totalApproximateEarnings,
    required this.fetchedAt,
    required this.currency,
  });

  final String pageId;

  /// `content_monetization_earnings` total for the range, when reported.
  final double? totalEarnings;

  /// `monetization_approximate_earnings` total for the range, when reported.
  final double? totalApproximateEarnings;
  final DateTime fetchedAt;

  /// Graph rarely returns a currency; empty means Page currency.
  final String currency;

  bool get hasAny => totalEarnings != null || totalApproximateEarnings != null;
}
