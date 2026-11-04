import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_page_service.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Publisher stub — `verify` outcome swapped per test. The base class only
/// needs an `ApiClient` for real calls; the override never touches it.
class _StubPublisher extends FacebookPublisherService {
  _StubPublisher({this.page, this.error}) : super(ApiClient());

  final FacebookPage? page;
  final FacebookApiException? error;

  @override
  Future<FacebookPage> verify(String token) async {
    if (error != null) throw error!;
    return page!;
  }
}

class _StubPageService extends FacebookPageService {
  _StubPageService(this.accounts) : super(ApiClient());

  final List<FacebookPageAccount> accounts;

  @override
  Future<List<FacebookPageAccount>> listPagesFromUserToken(
    String userToken,
  ) async => accounts;

  @override
  Future<FacebookPage> verifyPageToken(String token) async =>
      accounts.first.page;
}

class _LifecyclePublisher extends FacebookPublisherService {
  _LifecyclePublisher() : super(ApiClient());

  bool deleted = false;
  bool edited = false;
  String? editedMessage;

  @override
  Future<void> deletePost({
    required String postId,
    required String token,
  }) async {
    deleted = true;
  }

  @override
  Future<void> updatePostMessage({
    required String postId,
    required String token,
    required String message,
  }) async {
    edited = true;
    editedMessage = message;
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
  });

  tearDown(() {
    getIt.reset();
  });

  Future<ProviderContainer> setUpVm({
    required FacebookPublisherService stub,
    FacebookPageService? pageService,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<PreferencesService>(
      () => PreferencesService(
        prefs: prefs,
        secureStorage: FlutterSecureStorage(),
      ),
    );
    getIt.registerLazySingleton<FacebookPublisherService>(() => stub);
    if (pageService != null) {
      getIt.registerLazySingleton<FacebookPageService>(() => pageService);
    }
    final container = ProviderContainer();
    // Trigger build (loads page identity from prefs).
    container.read(facebookViewModelProvider);
    return container;
  }

  group('FacebookNotifier', () {
    test('notConnected when no Page identity persisted', () async {
      final container = await setUpVm(stub: _StubPublisher());
      expect(
        container.read(facebookViewModelProvider).status,
        FacebookConnectionStatus.notConnected,
      );
      container.dispose();
    });

    test(
      'connected when Page identity persisted from a previous session',
      () async {
        final container = await setUpVm(
          stub: _StubPublisher(
            page: const FacebookPage(id: '123', name: 'Trace'),
          ),
        );
        final notifier = container.read(facebookViewModelProvider.notifier);
        expect(notifier.state.status, FacebookConnectionStatus.notConnected);
        final error = await notifier.connect('EAAtestToken123');
        expect(error, isNull);
        final state = container.read(facebookViewModelProvider);
        expect(state.status, FacebookConnectionStatus.connected);
        expect(state.pageId, '123');
        expect(state.pageName, 'Trace');
        // Token + identity persisted.
        expect(
          container.read(facebookViewModelProvider).subtitle,
          'Connected · Trace',
        );
        container.dispose();
      },
    );

    test('token stored securely, not in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = await setUpVm(
        stub: _StubPublisher(
          page: const FacebookPage(id: '123', name: 'Trace'),
        ),
      );
      final notifier = container.read(facebookViewModelProvider.notifier);
      await notifier.connect('EAAtestToken123');
      // Prefs never hold the token.
      expect(prefs.getString('facebook_page_token'), isNull);
      expect(prefs.getString('facebook_page_id'), '123');
      expect(prefs.getString('facebook_page_name'), 'Trace');
      // Secure storage does (mock backend).
      expect(
        await getIt<PreferencesService>().getFacebookPageToken(),
        'EAAtestToken123',
      );
      container.dispose();
    });

    test(
      'failed verification leaves state unchanged and returns message',
      () async {
        final container = await setUpVm(
          stub: _StubPublisher(
            error: const FacebookApiException(
              kind: FacebookApiErrorKind.expiredToken,
              message: 'Facebook connection expired. Reconnect your Page.',
              code: 190,
            ),
          ),
        );
        final notifier = container.read(facebookViewModelProvider.notifier);
        final error = await notifier.connect('EAAtestToken123');
        final state = container.read(facebookViewModelProvider);
        expect(
          state.status,
          FacebookConnectionStatus.notConnected,
          reason: 'verification failed → nothing persisted',
        );
        expect(error, contains('Reconnect'));
        container.dispose();
      },
    );

    test(
      'markExpired flips connected → expired, compose can offer reconnect',
      () async {
        final container = await setUpVm(
          stub: _StubPublisher(
            page: const FacebookPage(id: '123', name: 'Trace'),
          ),
        );
        final notifier = container.read(facebookViewModelProvider.notifier);
        await notifier.connect('EAAtestToken123');
        notifier.markExpired();
        expect(
          container.read(facebookViewModelProvider).status,
          FacebookConnectionStatus.expired,
        );
        expect(
          container.read(facebookViewModelProvider).subtitle,
          contains('expired'),
        );
        // Idempotent when already expired? (re-marked after another 190)
        notifier.markExpired();
        expect(
          container.read(facebookViewModelProvider).status,
          FacebookConnectionStatus.expired,
        );
        container.dispose();
      },
    );

    test('user token exchange persists only derived Page tokens', () async {
      const userToken = 'EAAuserTokenSecret';
      final pageService = _StubPageService([
        FacebookPageAccount(
          page: const FacebookPage(id: 'a', name: 'Page A'),
          pageToken: 'page-token-a',
        ),
        FacebookPageAccount(
          page: const FacebookPage(id: 'b', name: 'Page B'),
          pageToken: 'page-token-b',
        ),
      ]);
      final container = await setUpVm(
        stub: _StubPublisher(),
        pageService: pageService,
      );
      final notifier = container.read(facebookViewModelProvider.notifier);
      final error = await notifier.connectWithUserToken(userToken);
      expect(error, isNull);

      final state = container.read(facebookViewModelProvider);
      expect(state.pages.map((p) => p.id), ['a', 'b']);
      expect(state.activePageId, 'a');
      expect(state.pageName, 'Page A');
      expect(state.hasMultiplePages, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final secure = FlutterSecureStorage();
      expect(
        await getIt<PreferencesService>().getFacebookPageTokenFor('a'),
        'page-token-a',
      );
      expect(
        await getIt<PreferencesService>().getFacebookPageTokenFor('b'),
        'page-token-b',
      );
      // The user token is discarded: not in prefs, not in secure storage.
      for (final key in prefs.getKeys()) {
        expect(prefs.get(key).toString(), isNot(contains(userToken)));
      }
      expect(await secure.read(key: 'facebook_page_token'), isNull);

      // Switching changes the publish target without touching tokens.
      await notifier.switchPage('b');
      expect(container.read(facebookViewModelProvider).activePageId, 'b');
      expect(
        await getIt<PreferencesService>().getFacebookPageToken(),
        'page-token-b',
      );

      // Disconnecting the active Page keeps Page A's token.
      await notifier.disconnectActivePage();
      final after = container.read(facebookViewModelProvider);
      expect(after.pages.map((p) => p.id), ['a']);
      expect(after.activePageId, 'a');
      expect(
        await getIt<PreferencesService>().getFacebookPageTokenFor('b'),
        isNull,
      );
      expect(
        await getIt<PreferencesService>().getFacebookPageTokenFor('a'),
        'page-token-a',
      );
      container.dispose();
    });

    test(
      'history notifier deletes and edits published posts via Graph',
      () async {
        final publisher = _LifecyclePublisher();
        final container = await setUpVm(stub: publisher);
        final prefs = getIt<PreferencesService>();
        await prefs.setFacebookPageToken('EAAhistoryToken');
        final history = getIt<FacebookHistoryService>();
        final record = await history.recordPublish(
          postId: '123_9',
          message: 'Original',
          permalink: 'https://www.facebook.com/123_9',
          hasImage: false,
        );
        expect(container.read(facebookHistoryProvider), hasLength(1));

        final notifier = container.read(facebookHistoryProvider.notifier);
        final editError = await notifier.editPublishedPost(
          record.id,
          'Updated caption',
        );
        expect(editError, isNull);
        expect(publisher.edited, isTrue);
        expect(publisher.editedMessage, 'Updated caption');
        expect(
          container.read(facebookHistoryProvider).single.message,
          'Updated caption',
        );

        final deleteError = await notifier.deletePublishedPost(record.id);
        expect(deleteError, isNull);
        expect(publisher.deleted, isTrue);
        expect(container.read(facebookHistoryProvider), isEmpty);
        container.dispose();
      },
    );

    test('startup maintenance does not form a provider cycle', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'facebook_last_sweep',
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setInt('facebook_last_reconcile', 0);
      final container = await setUpVm(stub: _StubPublisher());
      // Let the deferred maintenance microtask run.
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(facebookDraftProvider),
        isA<FacebookComposeState>(),
      );
      container.dispose();
    });

    test('disconnect clears token, identity and state', () async {
      final container = await setUpVm(
        stub: _StubPublisher(
          page: const FacebookPage(id: '123', name: 'Trace'),
        ),
      );
      final notifier = container.read(facebookViewModelProvider.notifier);
      await notifier.connect('EAAtestToken123');
      final prefs = getIt<PreferencesService>();
      expect(await prefs.getFacebookPageToken(), isNotNull);

      await notifier.disconnect();
      expect(await prefs.getFacebookPageToken(), isNull);
      expect(prefs.facebookPageId, isNull);
      expect(prefs.facebookPageName, isNull);
      expect(
        container.read(facebookViewModelProvider).status,
        FacebookConnectionStatus.notConnected,
      );
      container.dispose();
    });
  });
}
