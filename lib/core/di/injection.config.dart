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

import '../../data/repositories/tavily_search_repository.dart' as _i389;
import '../../data/services/card_data_extractor.dart' as _i633;
import '../../data/services/export_service.dart' as _i496;
import '../../data/services/log_service.dart' as _i713;
import '../../data/services/preferences_service.dart' as _i867;
import '../../data/services/provider_api_service.dart' as _i581;
import '../../data/services/usage_service.dart' as _i1062;
import '../../data/services/web_scraper_service.dart' as _i978;
import '../../domain/repositories/search_repository.dart' as _i475;
import '../../domain/services/enrich_context_usecase.dart' as _i253;
import '../network/api_client.dart' as _i557;
import '../repositories/card_repository.dart' as _i83;
import '../repositories/content_repository.dart' as _i739;
import '../repositories/settings_repository.dart' as _i2;
import '../repositories/usage_repository.dart' as _i671;
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
    gh.lazySingleton<_i739.IContentRepository>(() => _i739.ContentRepository());
    gh.lazySingleton<_i867.PreferencesService>(
      () => _i867.PreferencesService(
        prefs: gh<_i460.SharedPreferences>(),
        secureStorage: gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i2.ISettingsRepository>(
      () => _i2.SettingsRepository(gh<_i867.PreferencesService>()),
    );
    gh.lazySingleton<_i83.ICardRepository>(
      () => _i83.CardRepository(gh<_i633.CardDataExtractor>()),
    );
    gh.lazySingleton<_i713.LogService>(
      () => _i713.LogService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1062.UsageService>(
      () => _i1062.UsageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i581.ProviderApiService>(
      () => _i581.ProviderApiService(gh<_i557.ApiClient>()),
    );
    gh.lazySingleton<_i978.WebScraperService>(
      () => _i978.WebScraperService(gh<_i557.ApiClient>()),
    );
    gh.lazySingleton<_i475.ISearchRepository>(
      () => _i389.TavilySearchRepository(
        gh<_i557.ApiClient>(),
        gh<_i867.PreferencesService>(),
      ),
    );
    gh.lazySingleton<_i671.IUsageRepository>(
      () => _i671.UsageRepository(gh<_i1062.UsageService>()),
    );
    gh.factory<_i253.EnrichContextUseCase>(
      () => _i253.EnrichContextUseCase(
        gh<_i475.ISearchRepository>(),
        gh<_i978.WebScraperService>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
