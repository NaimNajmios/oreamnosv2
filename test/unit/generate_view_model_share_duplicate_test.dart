import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/repositories/content_repository.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class _GatedRepository implements IContentRepository {
  final Completer<Result<CuratedPost>> _gate = Completer<Result<CuratedPost>>();
  int callCount = 0;

  void complete() {
    if (!_gate.isCompleted) {
      _gate.complete(
        const ResultSuccess(
          CuratedPost(
            title: 'Headline',
            bodyMarkdown: 'Body',
            hashtags: ['Tag'],
            source: SourceAttribution(label: 'source'),
            rawMarkdown: 'Raw',
          ),
        ),
      );
    }
  }

  @override
  Future<Result<CuratedPost>> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
    List<String> searchSources = const [],
    bool keepStructure = false,
    bool isFanModeEnabled = false,
    String fanClubName = '',
    String length = 'medium',
    String? siteName,
    String? authorDisplayName,
    String? candidateOutlet,
    bool isTwitter = false,
    Uint8List? imageBytes,
    String? imageMimeType,
    CancelToken? cancelToken,
  }) async {
    callCount++;
    return _gate.future;
  }

  @override
  Future<Result<CuratedPost>> refinePost({
    required CuratedPost original,
    required List<String> refinements,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    bool includeSource = true,
    bool keepStructure = false,
    String length = 'medium',
    bool isFanModeEnabled = false,
    String fanClubName = '',
    CancelToken? cancelToken,
  }) async {
    callCount++;
    return _gate.future;
  }

  @override
  Future<Result<String>> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  }) async {
    return const ResultSuccess('Plain text');
  }

  @override
  Future<Result<String>> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
  }) async {
    return const ResultSuccess('Rewritten');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Duplicate share handling', () {
    late ProviderContainer container;
    late _GatedRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final prefService = PreferencesService(
        prefs: prefs,
        secureStorage: storage,
      );
      await prefService.setApiKey(AiProvider.gemini, 'fake-key');
      await prefService.setSelectedModel(AiProvider.gemini, 'gemini-2.0-flash');

      await getIt.reset();
      await configureDependencies();
      getIt.allowReassignment = true;
      getIt.registerLazySingleton<PreferencesService>(() => prefService);
      getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
      getIt.registerLazySingleton<LogService>(() => LogService(prefs));

      repo = _GatedRepository();
      container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(repo)],
      );
      final settings = container.read(settingsViewModelProvider.notifier);
      await settings.setSelectedProvider(AiProvider.gemini);
      await settings.setSelectedModel('gemini-2.0-flash');
    });

    tearDown(() => container.dispose());

    test('a duplicate share while generating does not start a second '
        'generation', () async {
      final vm = container.read(generateViewModelProvider.notifier);
      // Plain text keeps the pipeline on the repository mock (a tweet URL
      // would detour into FxTwitter extraction).
      const link = 'plain text news';

      final first = vm.handleExternalSharedInput(link);
      // Let the pre-flight key lookup finish so the repository call is live.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.callCount, 1);

      // Android rebounces the same share after the service dedup window.
      await vm.handleExternalSharedInput(link);
      expect(repo.callCount, 1);
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.generating,
      );

      repo.complete();
      await first;
      expect(repo.callCount, 1);
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.success,
      );
    });

    test('the same content can be generated again after the first attempt '
        'settles', () async {
      final vm = container.read(generateViewModelProvider.notifier);
      // Plain text keeps the pipeline on the repository mock (a tweet URL
      // would detour into FxTwitter extraction).
      const link = 'plain text news';

      final first = vm.handleExternalSharedInput(link);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      repo.complete();
      await first;
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.success,
      );

      final second = vm.handleExternalSharedInput(link);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.callCount, 2);
      repo.complete();
      await second;
    });
  });
}
