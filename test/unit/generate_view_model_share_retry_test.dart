import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

/// Script-driven mock mirroring rate_limit_flow_test's approach.
class _MockContentRepository implements IContentRepository {
  final List<Result<CuratedPost>> _script = [];
  int callCount = 0;
  AiProvider? lastProvider;

  void queue(Result<CuratedPost> result) => _script.add(result);

  Result<CuratedPost> _next() {
    if (_script.isNotEmpty) return _script.removeAt(0);
    return const ResultSuccess(
      CuratedPost(
        title: 'Test Headline',
        bodyMarkdown: 'Test Body Markdown',
        hashtags: ['TestHashtag'],
        source: SourceAttribution(label: 'source'),
        rawMarkdown: 'Test Raw Markdown',
      ),
    );
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
  }) async {
    callCount++;
    lastProvider = provider;
    return _next();
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
  }) async {
    callCount++;
    lastProvider = provider;
    return _next();
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

  group('Share-initiated auto-retry', () {
    late ProviderContainer container;
    late _MockContentRepository mockRepo;
    late PreferencesService prefService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      prefService = PreferencesService(prefs: prefs, secureStorage: storage);
      await prefService.setApiKey(AiProvider.gemini, 'fake-gemini-key');
      await prefService.setSelectedModel(AiProvider.gemini, 'gemini-2.0-flash');

      await getIt.reset();
      await configureDependencies();
      getIt.allowReassignment = true;
      getIt.registerLazySingleton<PreferencesService>(() => prefService);
      getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
      getIt.registerLazySingleton<LogService>(() => LogService(prefs));

      mockRepo = _MockContentRepository();
      container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(mockRepo)],
      );
      final settings = container.read(settingsViewModelProvider.notifier);
      await settings.setSelectedProvider(AiProvider.gemini);
      await settings.setSelectedModel('gemini-2.0-flash');
    });

    tearDown(() {
      container.dispose();
    });

    test('retries transient NetworkFailure failures and succeeds without '
        'surfacing an error', () async {
      mockRepo.queue(const ResultError(NetworkFailure('offline')));
      mockRepo.queue(const ResultError(NetworkFailure('offline again')));

      final vm = container.read(generateViewModelProvider.notifier);
      await vm.handleExternalSharedInput('plain text news');

      final state = container.read(generateViewModelProvider);
      // 3 attempts: initial + 2 auto retries.
      expect(mockRepo.callCount, 3);
      expect(state.status, GenerateState.success);
      expect(state.curatedPost, isNotNull);
      expect(state.errorMessage, isNull);
      expect(state.isFromShare, isTrue);
      expect(state.pendingInput, contains('plain text news'));
      expect(state.fallbackNotice, isNull);
    });

    test('does not auto-retry auth failures', () async {
      mockRepo.queue(const ResultError(AuthFailure('bad key')));

      final vm = container.read(generateViewModelProvider.notifier);
      await vm.handleExternalSharedInput('plain text news');

      final state = container.read(generateViewModelProvider);
      expect(mockRepo.callCount, 1);
      expect(state.status, GenerateState.error);
      expect(state.errorMessage, contains('Authentication failed'));
    });

    test('stops after max retries and surfaces the error', () async {
      mockRepo.queue(const ResultError(NetworkFailure('n1')));
      mockRepo.queue(const ResultError(NetworkFailure('n2')));
      mockRepo.queue(const ResultError(NetworkFailure('n3')));

      final vm = container.read(generateViewModelProvider.notifier);
      await vm.handleExternalSharedInput('plain text news');

      final state = container.read(generateViewModelProvider);
      expect(mockRepo.callCount, 3);
      expect(state.status, GenerateState.error);
      expect(state.errorMessage, contains('Network error'));
      // Input preserved for one-tap retry.
      expect(state.pendingInput, contains('plain text news'));
    });

    test(
      'manual (non-share) generation does not auto-retry transient failures',
      () async {
        mockRepo.queue(const ResultError(NetworkFailure('n1')));

        final vm = container.read(generateViewModelProvider.notifier);
        await vm.generatePost('plain text news');

        final state = container.read(generateViewModelProvider);
        expect(mockRepo.callCount, 1);
        expect(state.status, GenerateState.error);
        expect(state.isFromShare, isFalse);
      },
    );
  });
}
