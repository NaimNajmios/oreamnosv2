// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/services/card_data_extractor.dart' as _i633;
import '../../data/services/export_service.dart' as _i496;
import '../../data/services/log_service.dart' as _i713;
import '../../data/services/preferences_service.dart' as _i867;
import '../../data/services/usage_service.dart' as _i1062;
import '../network/api_client.dart' as _i557;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i557.ApiClient>(() => _i557.ApiClient());
    gh.lazySingleton<_i633.CardDataExtractor>(() => _i633.CardDataExtractor());
    gh.lazySingleton<_i496.ExportService>(() => _i496.ExportService());
    gh.lazySingleton<_i867.PreferencesService>(
      () => _i867.PreferencesService(
        prefs: gh<_i460.SharedPreferences>(),
        secureStorage: gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i713.LogService>(
      () => _i713.LogService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1062.UsageService>(
      () => _i1062.UsageService(gh<_i460.SharedPreferences>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
