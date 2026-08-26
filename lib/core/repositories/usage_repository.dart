import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../core/di/injection.dart';
import '../../data/services/usage_service.dart';
import '../../domain/models/usage_log.dart';

abstract class IUsageRepository {
  List<UsageLog> get logs;
  Future<void> logUsage(UsageLog log);
  void clear();
}

@LazySingleton(as: IUsageRepository)
class UsageRepository implements IUsageRepository {
  final UsageService _service;
  UsageRepository(this._service);

  @override
  List<UsageLog> get logs => _service.logs;
  @override
  Future<void> logUsage(UsageLog log) async => _service.logUsage(log);
  @override
  void clear() => _service.clearLogs();
}

final usageRepositoryProvider = Provider<IUsageRepository>(
  (ref) => getIt<IUsageRepository>(),
);
