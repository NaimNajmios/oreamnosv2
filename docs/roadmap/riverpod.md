# Roadmap — Riverpod Full Migration (Notifier)

> Current: `ChangeNotifierProvider` compat `lib/ui/features/generate/view_models/generate_view_model.dart:34` + `getIt` delegation `lib/ui/features/generate/view_models/generate_view_model.dart:67` + `provider: ^6.1.4` shim `pubspec.yaml:18`.

## Current Hybrid

* `GenerateViewModel extends ChangeNotifier with WidgetsBindingObserver:40`, `CardGeneratorViewModel:31`, `SettingsViewModel:11`, `UsageService:12`, `LogService:98`.
* `GenerateViewModel(this.ref){ _settingsViewModel=ref.read(settingsViewModelProvider):66; _usageService=getIt<UsageService>():67 }` mixes `Ref` + `getIt`.
* Tests hack `getIt.allowReassignment` `test/generate_view_model_test.dart:45` instead of `ProviderContainer(overrides:[])`.

## Plan (separate doc, full migration now — per user: if no space, fully immigrate now)

1. `GenerateViewModel` → `class GenerateViewModel extends Notifier<GenerateState>` or `AsyncNotifier<CuratedPost?>` (Riverpod 2.6 `Notifier`, not `riverpod_generator` yet due to `analyzer 13.3.0` pin `analysis_options.yaml:23`).
2. `cardGeneratorViewModelProvider` + `settingsViewModelProvider` similarly.
3. Remove `provider: ^6.1.4` `pubspec.yaml:18`; delete `ChangeNotifier` imports; expose `ref.read(usageServiceProvider)` etc. via Riverpod.
4. Enable `riverpod_lint` `analysis_options.yaml:23` after `freezed 4.0` + `analyzer 14` bump (Phase E).
5. Update `test/helpers/test_helpers.dart:48` `withProviderScope(overrides: [generateViewModelProvider.overrideWith(...)])`.

## Verification

* `flutter analyze 0`; `flutter test --coverage` 75; no `getIt<UsageService>` in ViewModels; `pubspec remove provider`.

