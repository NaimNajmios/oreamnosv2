import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
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
  });
}
