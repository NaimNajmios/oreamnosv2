# Contributing — Oreamnos

## Prerequisites

* Flutter `3.47.1` stable + Dart `^3.13.1` (`flutter --version`).
* `get_it`/`injectable` generator: `dart run build_runner build --delete-conflicting-outputs`.

## Workflow

1. **Branch from `main`** and inspect diffs before committing:

```bash
git status
git diff
git log --oneline -10
```

2. **Codegen first:**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

3. **CI gates (must be 0):**

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
```

`ci.yaml:20` runs these 4 + `build_runner` on `push: [main,master]` and `pull_request: [main,master]`.

## Conventions

* Citations: `file_path:line_number` for every function reference.
* `ChangeNotifierProvider` compat → migrated to `Notifier` in Phase D; prefer `ref.watch/read` over `getIt` where possible.
* Secrets: `PreferencesService` + `flutter_secure_storage` (`encryptedSharedPreferences:true` `lib/main.dart:26`), never log `apiKey`.
* Routing: add new route in `lib/config/routes/app_router.dart:16` (`RoutePaths` + `GoRouter`), decide Shell vs full-screen.

## Review checklist

* `dart format` 0 changed, `flutter analyze` 0 issues, `flutter test --coverage` 75 passed, `injection.config.dart:42` updated if new `@lazySingleton`.

## Design system

See `docs/design-system-threads.md` — tokens `lib/config/theme/app_spacing.dart:4`, 9 themes `lib/domain/models/app_theme_mode.dart:2` horizontal scroll `settings_screen.dart:55`, `AppCard 16dp` / `AppChip pill` / `AppInput 12dp`.

