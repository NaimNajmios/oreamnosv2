import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_diagnostics.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/views/facebook_diagnostics_screen.dart';

const _token = 'EAAtestSECRETtoken123';
const _caption = 'Secret match caption #FAM';
const _url = 'https://graph.facebook.com/v21.0/123/posts?access_token=$_token';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;
    getIt<LogService>().clear();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('FacebookDiagnostics', () {
    test('records a redacted taxonomy for a Graph failure', () async {
      const error = FacebookApiException(
        kind: FacebookApiErrorKind.expiredToken,
        message: 'expired $_caption $_url',
        code: 190,
        subcode: 463,
      );

      FacebookDiagnostics.failure(
        'Publish',
        error,
        statusCode: 400,
        pageId: '123',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final entry = getIt<LogService>().logs.single;
      expect(entry.tag, 'Facebook');
      expect(entry.level, 'ERROR');
      expect(entry.message, 'Publish failed');
      expect(entry.details, contains('kind=expiredToken'));
      expect(entry.details, contains('code=190'));
      expect(entry.details, contains('subcode=463'));
      expect(entry.details, contains('status=400'));
      expect(entry.details, contains('page=123'));
      expect(entry.details, isNot(contains(_token)));
      expect(entry.details, isNot(contains(_caption)));
      expect(entry.details, isNot(contains('graph.facebook.com')));
      expect(entry.error, isNull);
    });

    test('unknown errors expose only the runtime type', () async {
      FacebookDiagnostics.failure(
        'Publish',
        StateError('caption $_caption token $_token $_url'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final entry = getIt<LogService>().logs.single;
      expect(entry.details, 'kind=StateError');
      expect(entry.details, isNot(contains(_token)));
      expect(entry.details, isNot(contains(_caption)));
    });

    test('network issues include the normalized issue name', () {
      expect(
        FacebookDiagnostics.describe(
          const FacebookApiException(
            kind: FacebookApiErrorKind.network,
            message: 'offline',
            networkIssue: FacebookNetworkIssue.timeout,
          ),
        ),
        contains('networkIssue=timeout'),
      );
    });

    test('events log at debug level without payloads', () async {
      FacebookDiagnostics.event('Published post', pageId: '123');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final entry = getIt<LogService>().logs.single;
      expect(entry.level, 'DEBUG');
      expect(entry.tag, 'Facebook');
      expect(entry.details, 'page=123');
    });
  });

  test('copied summary stays redacted and includes sync state', () async {
    final summary = buildFacebookDiagnosticsSummary(
      connection: const FacebookUiState(
        status: FacebookConnectionStatus.connected,
        pageId: '123',
        pageName: 'Trace',
        lastHealthErrorKind: 'network',
      ),
      lastReconcile: DateTime(2026, 11, 11, 9, 30),
      scheduledCount: 2,
      scheduledSyncFailed: true,
      logs: [
        LogEntry(
          timestamp: DateTime(2026, 11, 11, 9, 31),
          level: 'ERROR',
          message: 'Publish failed',
          tag: 'Facebook',
          details: 'kind=expiredToken code=190',
        ),
      ],
    );

    expect(summary, contains('status=connected'));
    expect(summary, contains('pageId=123'));
    expect(summary, contains('scheduledCount=2'));
    expect(summary, contains('scheduledSyncFailed=true'));
    expect(summary, contains('kind=expiredToken'));
    expect(summary, isNot(contains(_token)));
    expect(summary, isNot(contains(_caption)));
    expect(summary, isNot(contains('graph.facebook.com')));
  });
}
