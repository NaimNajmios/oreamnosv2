# Roadmap — http Removal

> `pubspec.yaml:25` `http: ^1.4.0` still listed; `grep "import.*http" lib/` = 0 after Phase B dio migration (`WebScraperService 10` + `ProviderApiService 17` via `ApiClient` `lib/core/network/api_client.dart:23`). Only probes `test_scraper.dart:3` + `test_isurl.dart`.

## Plan (separate doc)

1. Move `test_scraper.dart` + `test_isurl.dart` → `tool/scrape_probe.dart` (not `lib/`), or delete.
2. `flutter pub remove http` → `pubspec.lock` drops `http 1.4.0`.
3. `flutter pub get` + `dart run build_runner build` + `flutter analyze 0` + `flutter test 75`.

