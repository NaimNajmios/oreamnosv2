# Oreamnos — Phase D Baseline (2026-09-03)

> Complete ChangeNotifier elimination + Notifier architecture convergence + dead code cleanup + AppConstants alignment + test depth expansion — supersedes docs/baseline-phaseC.md.

## Environment
* Flutter 3.47.1 stable · Dart 3.13.1 · flutter --version verified lib/main.dart:26 ProviderScope + configureDependencies() (getIt.init).
* Stack pubspec.yaml:53 dio 5.11.0, flutter_riverpod 2.6.1 / riverpod 2.6.1, freezed 4.0.0 / freezed_annotation 3.1.0, get_it 9.2.1 / injectable 3.0.0, go_router 14.8.1, gal 2.3.3, image_picker 1.2.3.
* Zero ChangeNotifierProvider declarations remaining in the entire codebase.

## Verification (post Phase D)
* dart format --output=none --set-exit-if-changed . -> 0 changed
* flutter analyze -> No issues found!
* flutter test -> 117 passed across 21 test files (rate limit fallback chain, card generator VM snapshots, 17 canvas renderers, interceptors, curators, contract tests).

## What Phase D Shipped (vs Phase C docs/baseline-phaseC.md)
| Area | Phase C | Phase D |
|---|---|---|
| State Management | LogService & UsageService used ChangeNotifierProvider | Complete Notifier migration: LogNotifier and UsageNotifier replace all ChangeNotifierProviders |
| Dead Code & Hygiene | Unused containsQuotes, isLongTechnicalContent, _sparseSchema, .tmp file | Pruned: Removed unused detection methods, pruned cutoutPath and elementOffsets from CardConfig, deleted orphaned .tmp file |
| Network Alignment | AppConstants.maxRetries=5 differed from RetryInterceptor(4) | Aligned: ApiClient directly consumes AppConstants timeouts and retry parameters |
| Resilience Verification | Unverified rate-limit dialog & fallback chain | Verified with unit test: test/unit/rate_limit_flow_test.dart confirms 429 -> RateLimitFailure -> rateLimited state -> fallback chain -> retryWithProvider |
| Card Generator VM | Undo/redo stack & field editing unverified | Verified with unit test: test/unit/card_generator_vm_test.dart verifies snapshot creation, undo, redo, 50-item cap, scale clamping, and field updating |
| Test Depth | 106 tests | 117 tests across 21 test files in test/ |

## Architecture Summary
- All 5 ViewModels / Notifiers (GenerateViewModel, CardGeneratorViewModel, SettingsNotifier, LogNotifier, UsageNotifier) now strictly conform to Riverpod Notifier<T> pattern with immutable states.
- Underlying background services (LogService, UsageService) remain pure, testable Dart singletons in GetIt without depending on Flutter widget lifecycle or ChangeNotifier.
