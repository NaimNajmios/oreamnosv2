import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_draft_store.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/data/services/facebook_story_composer.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GraphAdapter implements HttpClientAdapter {
  _GraphAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await for (final _ in requestStream ?? const Stream.empty()) {}
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FacebookPublisherService _fakePublisher(int status, Map<String, dynamic> body) {
  final apiClient = ApiClient();
  apiClient.dio.httpClientAdapter = _GraphAdapter(status, body);
  apiClient.dio.interceptors.clear();
  // `verify` is overridden so seeding the connection never depends on the
  // canned publish response; publish flows hit the adapter directly.
  return _FakePublisher(apiClient, status, body);
}

class _FakePublisher extends FacebookPublisherService {
  _FakePublisher(super.client, this.status, this.body);

  final int status;
  final Map<String, dynamic> body;

  @override
  Future<FacebookPage> verify(String token) async =>
      const FacebookPage(id: '123456', name: 'Trace');
}

class _FailingMultiPublisher extends FacebookPublisherService {
  _FailingMultiPublisher(super.client);

  final List<String> deleted = [];
  int uploads = 0;

  @override
  Future<FacebookPage> verify(String token) async =>
      const FacebookPage(id: '123456', name: 'Trace');

  @override
  Future<String> uploadUnpublishedPhoto({
    required String pageId,
    required String token,
    required String filePath,
    String? altText,
    ProgressCallback? onSendProgress,
  }) async {
    uploads++;
    if (uploads == 2) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.mediaUploadFailed,
        message: 'Second photo failed',
      );
    }
    return 'photo_$uploads';
  }

  @override
  Future<void> deletePhoto({
    required String photoId,
    required String token,
  }) async {
    deleted.add(photoId);
  }

  @override
  Future<FacebookPublishResult> publishMultiPhoto({
    required String pageId,
    required String token,
    required List<String> photoIds,
    required String message,
    DateTime? scheduledAt,
  }) async {
    throw StateError('feed must not be created after a failed upload');
  }
}

class _StoryPublisher extends FacebookPublisherService {
  _StoryPublisher({this.failStory = false}) : super(ApiClient());

  final bool failStory;
  int storyUploads = 0;

  @override
  Future<FacebookPage> verify(String token) async =>
      const FacebookPage(id: '123456', name: 'Trace');

  @override
  Future<FacebookPublishResult> publishText({
    required String pageId,
    required String token,
    required String message,
    DateTime? scheduledAt,
  }) async {
    return FacebookPublishResult(
      id: 'feed_1',
      postId: 'feed_1',
      permalink: 'https://www.facebook.com/feed_1',
      isPhoto: false,
      isScheduled: scheduledAt != null,
      scheduledAt: scheduledAt,
    );
  }

  @override
  Future<String> uploadUnpublishedPhoto({
    required String pageId,
    required String token,
    required String filePath,
    String? altText,
    ProgressCallback? onSendProgress,
  }) async {
    storyUploads++;
    return 'story_photo';
  }

  @override
  Future<FacebookStoryResult> publishPhotoStory({
    required String pageId,
    required String token,
    required String photoId,
  }) async {
    if (failStory) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.storyUnavailable,
        message: 'Story unavailable',
      );
    }
    return const FacebookStoryResult(postId: 'story_1');
  }

  @override
  Future<void> deletePhoto({
    required String photoId,
    required String token,
  }) async {}
}

class _FakeStoryComposer extends FacebookStoryComposer {
  @override
  Future<String> compose({
    String? sourceImagePath,
    required String title,
    required String outputDir,
  }) async {
    final file = File(
      '$outputDir/story_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes([1, 2, 3]);
    return file.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;
    FacebookDraftNotifier.onlineProbeOverride = () => true;
  });

  tearDown(() {
    FacebookDraftNotifier.onlineProbeOverride = null;
    getIt.reset();
  });

  Future<ProviderContainer> buildContainer(FacebookPublisherService pub) async {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<PreferencesService>(
      () => PreferencesService(
        prefs: prefs,
        secureStorage: FlutterSecureStorage(),
      ),
    );
    getIt.registerLazySingleton<FacebookPublisherService>(() => pub);
    final container = ProviderContainer();
    // Seed the connection state.
    final conn = container.read(facebookViewModelProvider.notifier);
    await conn.connect('EAAtestToken123');
    expect(container.read(facebookViewModelProvider).isConnected, isTrue);
    container.read(facebookDraftProvider);
    return container;
  }

  group('FacebookDraftNotifier', () {
    test('startDraft strips markdown into plain text', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      container
          .read(facebookDraftProvider.notifier)
          .startDraft(
            '**FT: JDT 4 - 1** #FAM\n\n[Source](https://example.com)',
          );
      final draft = container.read(facebookDraftProvider);
      expect(draft.text, 'FT: JDT 4 - 1 #FAM\n\nSource (https://example.com)');
      expect(draft.hasText, isTrue);
      expect(draft.imagePath, isNull);
      container.dispose();
    });

    test('setDraftText / attachImage / removeImage track edits', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Hello');
      notifier.setDraftText('Hello edited');
      expect(container.read(facebookDraftProvider).text, 'Hello edited');
      expect(
        await notifier.attachImage(ImageSource.gallery),
        isFalse,
        reason: 'no plugin in test env → cancel treated as no-image',
      );
      container.dispose();
    });

    test('publish with empty text is a no-op', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      await notifier.publish();
      expect(
        container.read(facebookDraftProvider).phase,
        FacebookComposePhase.editing,
      );
      container.dispose();
    });

    test(
      'publish text succeeds → published with permalink; then clearDraft',
      () async {
        final container = await buildContainer(
          _fakePublisher(200, {'id': '999_888'}),
        );
        final notifier = container.read(facebookDraftProvider.notifier);
        notifier.startDraft('FT: JDT wins #FAM');
        await notifier.publish();
        final draft = container.read(facebookDraftProvider);
        expect(draft.phase, FacebookComposePhase.published);
        expect(draft.result?.permalink, 'https://www.facebook.com/999_888');
        expect(draft.error, isNull);
        // History written (service registered by configureDependencies on
        // the mock prefs, so a restarted app reloads the same records).
        expect(
          getIt<FacebookHistoryService>().records.single.postId,
          '999_888',
        );

        notifier.clearDraft();
        expect(
          container.read(facebookDraftProvider).phase,
          FacebookComposePhase.editing,
        );
        container.dispose();
      },
    );

    test('offline probe failure surfaces a network error', () async {
      FacebookDraftNotifier.onlineProbeOverride = () => false;
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Hello');
      await notifier.publish();
      final draft = container.read(facebookDraftProvider);
      expect(draft.phase, FacebookComposePhase.publishError);
      expect(draft.error?.kind, FacebookApiErrorKind.network);
      container.dispose();
    });

    test('photo path publishes when an image is attached', () async {
      final container = await buildContainer(
        _fakePublisher(200, {'id': 'photo_1', 'post_id': '123456_88'}),
      );
      final tmp = await Directory.systemTemp.createTemp('oreamnos_fb');
      final file = File('${tmp.path}/card.png');
      await file.writeAsBytes(List<int>.generate(16, (i) => i));

      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Card caption #FAM', imagePath: file.path);
      await notifier.publish();
      final draft = container.read(facebookDraftProvider);
      expect(draft.phase, FacebookComposePhase.published);
      expect(draft.result?.isPhoto, isTrue);
      expect(draft.result?.permalink, 'https://www.facebook.com/123456_88');
      await tmp.delete(recursive: true);
      container.dispose();
    });

    test('expired-token publish marks the connection expired', () async {
      final container = await buildContainer(
        _fakePublisher(400, {
          'error': {'code': 190, 'message': 'Error validating access token'},
        }),
      );
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Hello');
      await notifier.publish();
      expect(
        container.read(facebookDraftProvider).error?.kind,
        FacebookApiErrorKind.expiredToken,
      );
      expect(
        container.read(facebookViewModelProvider).status,
        FacebookConnectionStatus.expired,
      );
      container.dispose();
    });

    test('duplicate rejection surfaces the duplicate kind', () async {
      final container = await buildContainer(
        _fakePublisher(400, {
          'error': {'code': 506, 'message': 'Duplicate Post'},
        }),
      );
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Same text');
      await notifier.publish();
      expect(
        container.read(facebookDraftProvider).error?.kind,
        FacebookApiErrorKind.duplicate,
      );
      // Connection stays connected — fix is editing, not reconnecting.
      expect(
        container.read(facebookViewModelProvider).status,
        FacebookConnectionStatus.connected,
      );
      container.dispose();
    });

    test('published draft is terminal — a second publish is a no-op', () async {
      final history = getIt<FacebookHistoryService>();
      final container = await buildContainer(
        _fakePublisher(200, {'id': '999_1'}),
      );
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Hello');
      await notifier.publish();
      expect(container.read(facebookDraftProvider).isPublished, isTrue);

      await notifier.publish();
      expect(history.records.length, 1, reason: 'no duplicate history row');
      container.dispose();
    });

    test('missing attachment surfaces a fixable error before Graph', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft(
        'Card caption',
        imagePath: '${Directory.systemTemp.path}/oreamnos_missing.png',
      );
      await notifier.publish();
      final draft = container.read(facebookDraftProvider);
      expect(draft.phase, FacebookComposePhase.publishError);
      expect(draft.error?.message, contains('no longer available'));
      container.dispose();
    });

    test('image aspect defaults to portrait and can be changed', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Hello', imagePath: 'card.png');
      expect(
        container.read(facebookDraftProvider).imageAspect,
        FacebookImageAspect.portrait,
      );
      notifier.setImageAspect(FacebookImageAspect.landscape);
      expect(
        container.read(facebookDraftProvider).imageAspect,
        FacebookImageAspect.landscape,
      );
      container.dispose();
    });

    test('draft autosaves and is restored by a fresh container', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      container
          .read(facebookDraftProvider.notifier)
          .setDraftText('Saved caption #FAM');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(
        getIt<FacebookDraftStore>().loadAll().single.text,
        'Saved caption #FAM',
      );
      container.dispose();

      final restored = ProviderContainer();
      expect(restored.read(facebookDraftProvider).text, 'Saved caption #FAM');
      restored.dispose();
    });

    test('appendDefaultHashtags appends once', () async {
      final prefs = getIt<PreferencesService>();
      await prefs.setDefaultHashtags('#FAM #JDT');
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('FT: JDT wins');
      expect(notifier.appendDefaultHashtags(), isTrue);
      expect(
        container.read(facebookDraftProvider).text,
        'FT: JDT wins\n\n#FAM #JDT',
      );
      expect(notifier.appendDefaultHashtags(), isTrue);
      expect(
        container.read(facebookDraftProvider).text,
        'FT: JDT wins\n\n#FAM #JDT',
      );
      container.dispose();
    });

    test('crop + alt text update the media item', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Card', imagePath: 'card.png');
      notifier.setMediaCrop(zoom: 2.5, offset: const Offset(0.4, -0.2));
      notifier.setAltText('Player celebrating');
      final media = container.read(facebookDraftProvider).mediaItem!;
      expect(media.zoom, 2.5);
      expect(media.offset.dx, closeTo(0.4, 0.001));
      expect(media.offset.dy, closeTo(-0.2, 0.001));
      expect(media.altText, 'Player celebrating');

      notifier.resetCrop();
      expect(container.read(facebookDraftProvider).mediaItem!.zoom, 1.0);
      expect(
        container.read(facebookDraftProvider).mediaItem!.offset,
        Offset.zero,
      );
      container.dispose();
    });

    test('schedule validation enforces the 10 min – 30 day window', () {
      final now = DateTime(2026, 11, 4, 12);
      expect(
        FacebookDraftNotifier.scheduleValidationError(
          now.add(const Duration(minutes: 9)),
          now: now,
        ),
        isNotNull,
      );
      expect(
        FacebookDraftNotifier.scheduleValidationError(
          now.add(const Duration(minutes: 10)),
          now: now,
        ),
        isNull,
      );
      expect(
        FacebookDraftNotifier.scheduleValidationError(
          now.add(const Duration(days: 30)),
          now: now,
        ),
        isNull,
      );
      expect(
        FacebookDraftNotifier.scheduleValidationError(
          now.add(const Duration(days: 31)),
          now: now,
        ),
        isNotNull,
      );
      expect(
        FacebookDraftNotifier.scheduleValidationError(
          now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        isNotNull,
      );
    });

    test('scheduled publish lands in scheduled phase + history', () async {
      final container = await buildContainer(
        _fakePublisher(200, {'id': 'sched_9'}),
      );
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Later #FAM');
      notifier.setScheduledAt(DateTime.now().add(const Duration(hours: 2)));
      await notifier.publish();
      final draft = container.read(facebookDraftProvider);
      expect(draft.phase, FacebookComposePhase.scheduled);
      expect(draft.result?.isScheduled, isTrue);
      expect(draft.result?.permalink, isEmpty);
      expect(
        getIt<FacebookHistoryService>().records.single.isScheduled,
        isTrue,
      );
      container.dispose();
    });

    test('publish rejects a missing schedule time', () async {
      final container = await buildContainer(_fakePublisher(200, {'id': 'p1'}));
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Later');
      notifier.setPublishMode(FacebookPublishMode.scheduled);
      await notifier.publish();
      final draft = container.read(facebookDraftProvider);
      expect(draft.phase, FacebookComposePhase.publishError);
      expect(draft.error?.message, contains('Pick a date'));
      container.dispose();
    });

    test('media helpers reorder, make cover and remove by id', () async {
      final prefs = getIt<PreferencesService>();
      await prefs.setFacebookDraftJson(
        jsonEncode(
          const FacebookDraftSnapshot(
            text: 'Three photos',
            media: [
              FacebookMediaItem(id: 'a', path: 'a.png'),
              FacebookMediaItem(id: 'b', path: 'b.png'),
              FacebookMediaItem(id: 'c', path: 'c.png'),
            ],
          ).toJson(),
        ),
      );
      final container = ProviderContainer();
      final notifier = container.read(facebookDraftProvider.notifier);
      var draft = container.read(facebookDraftProvider);
      expect(draft.media, hasLength(3));
      expect(draft.canAddMoreMedia, isTrue);
      expect(draft.mediaById('b')!.path, 'b.png');

      notifier.makeCover('c');
      draft = container.read(facebookDraftProvider);
      expect(draft.media.map((m) => m.id), ['c', 'a', 'b']);

      notifier.moveMedia(0, 2);
      draft = container.read(facebookDraftProvider);
      expect(draft.media.map((m) => m.id), ['a', 'b', 'c']);

      notifier.updateMedia('b', altText: 'Goalkeeper dive');
      expect(
        container.read(facebookDraftProvider).mediaById('b')!.altText,
        'Goalkeeper dive',
      );

      notifier.removeMedia('b');
      expect(container.read(facebookDraftProvider).media.map((m) => m.id), [
        'a',
        'c',
      ]);
      container.dispose();
    });

    test('the composer caps media at four photos', () {
      final draft = FacebookComposeState(
        media: List.generate(
          FacebookLimits.maxPhotos,
          (i) => FacebookMediaItem(id: 'm$i', path: '$i.png'),
        ),
      );
      expect(draft.canAddMoreMedia, isFalse);
      expect(draft.hasMultipleMedia, isTrue);
    });

    test(
      'multi-photo publish uploads each file then posts one feed entry',
      () async {
        final dir = await Directory.systemTemp.createTemp('oreamnos_fb_multi');
        final files = <File>[];
        for (var i = 0; i < 3; i++) {
          final file = File('${dir.path}/photo$i.png');
          await file.writeAsBytes(List<int>.generate(16, (i) => i));
          files.add(file);
        }
        final prefs = getIt<PreferencesService>();
        await prefs.setFacebookDraftJson(
          jsonEncode(
            FacebookDraftSnapshot(
              text: 'Matchday carousel #FAM',
              media: [
                for (var i = 0; i < files.length; i++)
                  FacebookMediaItem(id: 'm$i', path: files[i].path),
              ],
            ).toJson(),
          ),
        );
        final container = await buildContainer(
          _fakePublisher(200, {'id': 'post_1', 'post_id': '123_9'}),
        );
        final notifier = container.read(facebookDraftProvider.notifier);
        await notifier.publish();
        final draft = container.read(facebookDraftProvider);
        expect(draft.phase, FacebookComposePhase.published);
        expect(draft.result?.postId, '123_9');
        expect(draft.result?.isPhoto, isTrue);
        expect(getIt<FacebookHistoryService>().records.single.hasImage, isTrue);
        await dir.delete(recursive: true);
        container.dispose();
      },
    );

    test(
      'a failed multi-photo upload deletes uploads and creates no feed',
      () async {
        final dir = await Directory.systemTemp.createTemp('oreamnos_fb_fail');
        final files = <File>[];
        for (var i = 0; i < 2; i++) {
          final file = File('${dir.path}/photo$i.png');
          await file.writeAsBytes(List<int>.generate(16, (i) => i));
          files.add(file);
        }
        final prefs = getIt<PreferencesService>();
        await prefs.setFacebookDraftJson(
          jsonEncode(
            FacebookDraftSnapshot(
              text: 'Two photos',
              media: [
                for (var i = 0; i < files.length; i++)
                  FacebookMediaItem(id: 'm$i', path: files[i].path),
              ],
            ).toJson(),
          ),
        );
        final failing = _FailingMultiPublisher(ApiClient());
        final container = await buildContainer(failing);
        final notifier = container.read(facebookDraftProvider.notifier);
        await notifier.publish();
        final draft = container.read(facebookDraftProvider);
        expect(draft.phase, FacebookComposePhase.publishError);
        expect(draft.error?.kind, FacebookApiErrorKind.mediaUploadFailed);
        expect(failing.deleted, ['photo_1']);
        expect(getIt<FacebookHistoryService>().records, isEmpty);
        await dir.delete(recursive: true);
        container.dispose();
      },
    );

    test('feed + Story publishes both in one action', () async {
      getIt.unregister<FacebookStoryComposer>();
      getIt.registerLazySingleton<FacebookStoryComposer>(
        () => _FakeStoryComposer(),
      );
      final publisher = _StoryPublisher();
      final container = await buildContainer(publisher);
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Matchday caption #FAM');
      notifier.setStoryEnabled(true);
      notifier.setStoryTitle('Matchday');
      await notifier.publish();

      final draft = container.read(facebookDraftProvider);
      expect(draft.phase, FacebookComposePhase.published);
      expect(draft.result?.postId, 'feed_1');
      expect(draft.storyResult?.postId, 'story_1');
      expect(draft.storyError, isNull);
      expect(publisher.storyUploads, 1);

      final record = getIt<FacebookHistoryService>().records.single;
      expect(record.postId, 'feed_1');
      expect(record.storyStatus, FacebookStoryStatus.published);
      expect(record.storyPostId, 'story_1');
      container.dispose();
    });

    test(
      'Story failure leaves the feed post and marks partial success',
      () async {
        getIt.unregister<FacebookStoryComposer>();
        getIt.registerLazySingleton<FacebookStoryComposer>(
          () => _FakeStoryComposer(),
        );
        final container = await buildContainer(
          _StoryPublisher(failStory: true),
        );
        final notifier = container.read(facebookDraftProvider.notifier);
        notifier.startDraft('Caption');
        notifier.setStoryEnabled(true);
        notifier.setStoryTitle('Title');
        await notifier.publish();

        final draft = container.read(facebookDraftProvider);
        expect(draft.phase, FacebookComposePhase.partialSuccess);
        expect(draft.result?.postId, 'feed_1');
        expect(draft.storyError, isNotNull);
        final record = getIt<FacebookHistoryService>().records.single;
        expect(record.storyStatus, FacebookStoryStatus.failed);
        container.dispose();
      },
    );

    test('Story workflows cannot be scheduled', () async {
      getIt.unregister<FacebookStoryComposer>();
      getIt.registerLazySingleton<FacebookStoryComposer>(
        () => _FakeStoryComposer(),
      );
      final container = await buildContainer(_StoryPublisher());
      final notifier = container.read(facebookDraftProvider.notifier);
      notifier.startDraft('Caption');
      notifier.setStoryEnabled(true);
      notifier.setStoryTitle('Title');
      notifier.setScheduledAt(DateTime.now().add(const Duration(hours: 2)));
      await notifier.publish();
      final draft = container.read(facebookDraftProvider);
      expect(draft.phase, FacebookComposePhase.publishError);
      expect(
        draft.error?.kind,
        FacebookApiErrorKind.storySchedulingUnsupported,
      );
      container.dispose();
    });

    test('v9 draft JSON migrates into a media item and restores', () async {
      final prefs = getIt<PreferencesService>();
      await prefs.setFacebookDraftJson(
        jsonEncode({
          'text': 'Old draft #FAM',
          'imagePath': 'legacy.png',
          'aspect': 'square',
        }),
      );
      final container = ProviderContainer();
      final restored = container.read(facebookDraftProvider);
      expect(restored.text, 'Old draft #FAM');
      expect(restored.mediaItem?.path, 'legacy.png');
      expect(restored.imageAspect, FacebookImageAspect.square);
      expect(restored.restoredFromStorage, isTrue);
      container.dispose();
    });
  });
}
