import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePublisher extends FacebookPublisherService {
  _FakePublisher() : super();

  final List<String> uploaded = [];
  final List<String> deleted = [];
  int storyCalls = 0;
  bool failUploads = false;

  @override
  Future<String> uploadUnpublishedPhoto({
    required String pageId,
    required String token,
    required String filePath,
    String? altText,
    ProgressCallback? onSendProgress,
  }) async {
    if (failUploads) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.network,
        message: 'offline',
      );
    }
    uploaded.add(filePath);
    return 'photo_${uploaded.length}';
  }

  @override
  Future<FacebookStoryResult> publishPhotoStory({
    required String pageId,
    required String token,
    required String photoId,
  }) async {
    storyCalls++;
    return FacebookStoryResult(postId: 'story_$storyCalls');
  }

  @override
  Future<void> deletePhoto({
    required String photoId,
    required String token,
  }) async {
    deleted.add(photoId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePublisher publisher;
  late String imagePath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;
    publisher = _FakePublisher();
    getIt.registerLazySingleton<FacebookPublisherService>(() => publisher);
    final prefs = getIt<PreferencesService>();
    await prefs.setFacebookPageToken('token');
    final file = await File(
      '${Directory.systemTemp.path}/oreamnos_story_retry_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    ).create();
    await file.writeAsBytes([1, 2, 3]);
    imagePath = file.path;
  });

  tearDown(() async {
    try {
      await File(imagePath).delete();
    } catch (_) {}
    await getIt.reset();
  });

  Future<ProviderContainer> containerWith({
    int failedStories = 0,
    int publishedStories = 0,
  }) async {
    final service = getIt<FacebookHistoryService>();
    for (var i = 0; i < failedStories; i++) {
      await service.recordPublish(
        postId: 'post_f$i',
        message: 'Post f$i',
        permalink: 'https://facebook.com/post_f$i',
        hasImage: false,
        pageId: '123456',
        storyStatus: FacebookStoryStatus.failed,
        storyTitle: 'Title',
        storyImagePath: imagePath,
      );
    }
    for (var i = 0; i < publishedStories; i++) {
      await service.recordPublish(
        postId: 'post_p$i',
        message: 'Post p$i',
        permalink: 'https://facebook.com/post_p$i',
        hasImage: false,
        pageId: '123456',
        storyStatus: FacebookStoryStatus.published,
      );
    }
    final container = ProviderContainer();
    container.read(facebookHistoryProvider);
    return container;
  }

  group('retryFailedStories', () {
    test('retries only failed Stories and reports counts', () async {
      final container = await containerWith(
        failedStories: 2,
        publishedStories: 1,
      );

      final summary = await container
          .read(facebookHistoryProvider.notifier)
          .retryFailedStories();

      expect(summary.succeeded, 2);
      expect(summary.failed, 0);
      expect(publisher.storyCalls, 2);
      final records = container.read(facebookHistoryProvider);
      expect(records.every((r) => !r.storyFailed), isTrue);
      container.dispose();
    });

    test('continues after a failure and keeps the first error', () async {
      publisher.failUploads = true;
      final container = await containerWith(failedStories: 1);

      final summary = await container
          .read(facebookHistoryProvider.notifier)
          .retryFailedStories();

      expect(summary.succeeded, 0);
      expect(summary.failed, 1);
      expect(summary.firstError, 'offline');
      expect(
        container.read(facebookHistoryProvider).single.storyFailed,
        isTrue,
      );
      container.dispose();
    });

    test('missing Story image does not call Graph', () async {
      await File(imagePath).delete();
      final container = await containerWith(failedStories: 1);

      final summary = await container
          .read(facebookHistoryProvider.notifier)
          .retryFailedStories();

      expect(summary.failed, 1);
      expect(summary.firstError, contains('no longer available'));
      expect(publisher.uploaded, isEmpty);
      container.dispose();
    });

    test('empty failure list makes no calls', () async {
      final container = await containerWith();
      final summary = await container
          .read(facebookHistoryProvider.notifier)
          .retryFailedStories();
      expect(summary.isEmpty, isTrue);
      expect(publisher.storyCalls, 0);
      container.dispose();
    });
  });
}
