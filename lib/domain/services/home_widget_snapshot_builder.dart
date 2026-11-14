import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/models/home_widget_snapshot.dart';

/// One Gemini model's daily request count, decoupled from the data-layer
/// `DailyQuota` so this domain service stays free of `data/` imports.
class HomeWidgetQuota {
  const HomeWidgetQuota({
    required this.modelId,
    required this.requestsToday,
    required this.budget,
  });

  final String modelId;
  final int requestsToday;
  final int budget;
}

/// Builds the home-screen widget payload from already-loaded app state.
///
/// Pure and clock-injected so the whole contract is unit-testable without the
/// platform channel, and so previews/tests never depend on wall-clock time.
class HomeWidgetSnapshotBuilder {
  const HomeWidgetSnapshotBuilder();

  static const int maxSnippetChars = 90;

  HomeWidgetSnapshot build({
    required DateTime now,
    required List<FacebookPostRecord> records,
    required List<HomeWidgetQuota> quotas,
    required String pageName,
    required bool pageConnected,
    required bool pageExpired,
    required int draftCount,
    required HomeWidgetPalette palette,
    String? selectedProviderId,
    String? selectedModel,
    DateTime? quotaResetAt,
  }) {
    final scheduled =
        records
            .where((record) => record.isScheduled && record.scheduledAt != null)
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final next = scheduled.isEmpty ? null : scheduled.first;

    final quota = _pickQuota(quotas, selectedProviderId, selectedModel);

    return HomeWidgetSnapshot(
      updatedAt: now,
      nextSnippet: _clean(next?.snippet ?? ''),
      nextPage: next?.pageName.trim() ?? '',
      nextAt: next?.scheduledAt,
      // Scheduled records only carry the Story flag once it is known; a
      // Story-only record is the one case the widget can label confidently.
      nextIsStory: next?.isStoryOnly ?? false,
      scheduledCount: scheduled.length,
      draftCount: draftCount,
      quotaModel: quota == null ? null : _shortModel(quota.modelId),
      quotaUsed: quota?.requestsToday,
      quotaBudget: quota?.budget,
      quotaResetAt: quota == null ? null : quotaResetAt,
      pageName: pageName.trim(),
      pageConnected: pageConnected,
      pageExpired: pageExpired,
      palette: palette,
    );
  }

  /// The selected model's own row when Gemini is active, otherwise the busiest
  /// model of the day. Guessing a model would make the quota look wrong.
  static HomeWidgetQuota? _pickQuota(
    List<HomeWidgetQuota> quotas,
    String? selectedProviderId,
    String? selectedModel,
  ) {
    if (quotas.isEmpty) return null;

    final provider = (selectedProviderId ?? 'gemini').trim().toLowerCase();
    final model = _normalizeModel(selectedModel);
    if (provider == 'gemini' && model.isNotEmpty) {
      for (final quota in quotas) {
        if (_normalizeModel(quota.modelId) == model) return quota;
      }
    }

    var busiest = quotas.first;
    for (final quota in quotas) {
      if (quota.requestsToday > busiest.requestsToday) busiest = quota;
    }
    return busiest;
  }

  static String _normalizeModel(String? modelId) {
    var value = (modelId ?? '').trim().toLowerCase();
    if (value.startsWith('models/')) {
      value = value.substring('models/'.length);
    }
    return value;
  }

  /// `gemini-2.5-flash` → `2.5-flash`; the widget has no room for the vendor.
  static String _shortModel(String modelId) {
    final normalized = _normalizeModel(modelId);
    return normalized.startsWith('gemini-')
        ? normalized.substring('gemini-'.length)
        : normalized;
  }

  static String _clean(String value) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= maxSnippetChars) return collapsed;
    return '${collapsed.substring(0, maxSnippetChars - 1).trimRight()}…';
  }
}
