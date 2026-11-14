import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';

/// Persisted Usage range + provider filters.
class UsageFilter {
  const UsageFilter({this.rangeDays = 0, this.providerFilter = 'all'});

  /// 0 = all time, otherwise 7 / 30 / 90.
  final int rangeDays;
  final String providerFilter;

  UsageFilter copyWith({int? rangeDays, String? providerFilter}) {
    return UsageFilter(
      rangeDays: rangeDays ?? this.rangeDays,
      providerFilter: providerFilter ?? this.providerFilter,
    );
  }
}

final usageFilterProvider = NotifierProvider<UsageFilterNotifier, UsageFilter>(
  UsageFilterNotifier.new,
);

class UsageFilterNotifier extends Notifier<UsageFilter> {
  late final PreferencesService _prefs;

  @override
  UsageFilter build() {
    _prefs = getIt<PreferencesService>();
    return UsageFilter(
      rangeDays: _prefs.usageRangeDays,
      providerFilter: _prefs.usageProviderFilter,
    );
  }

  Future<void> setRangeDays(int days) async {
    final safe = days == 7 || days == 30 || days == 90 ? days : 0;
    if (state.rangeDays == safe) return;
    state = state.copyWith(rangeDays: safe);
    await _prefs.setUsageRangeDays(safe);
  }

  Future<void> setProviderFilter(String providerId) async {
    final safe = providerId.trim().isEmpty
        ? 'all'
        : providerId.trim().toLowerCase();
    if (state.providerFilter == safe) return;
    state = state.copyWith(providerFilter: safe);
    await _prefs.setUsageProviderFilter(safe);
  }

  Future<void> resetToAllTime() => setRangeDays(0);
}
