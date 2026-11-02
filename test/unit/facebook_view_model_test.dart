import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
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

  Future<ProviderContainer> setUpVm({required _StubPublisher stub}) async {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<PreferencesService>(
      () => PreferencesService(
        prefs: prefs,
        secureStorage: FlutterSecureStorage(),
      ),
    );
    getIt.registerLazySingleton<FacebookPublisherService>(() => stub);
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
