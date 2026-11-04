import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PreferencesService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = PreferencesService(
      prefs: prefs,
      secureStorage: FlutterSecureStorage(),
    );
  });

  const pageA = FacebookPage(id: 'a', name: 'Page A');
  const pageB = FacebookPage(id: 'b', name: 'Page B');

  group('per-page storage', () {
    test('tokens live under facebook_page_token_<pageId>', () async {
      await service.setFacebookPages([pageA, pageB]);
      await service.setFacebookPageTokenFor('a', 'token-a');
      await service.setFacebookPageTokenFor('b', 'token-b');
      await service.setFacebookActivePageId('a');

      expect(await service.getFacebookPageTokenFor('a'), 'token-a');
      expect(await service.getFacebookPageTokenFor('b'), 'token-b');
      // Legacy accessor resolves the active page.
      expect(await service.getFacebookPageToken(), 'token-a');
      expect(service.facebookPages, [pageA, pageB]);
      expect(service.facebookActivePageId, 'a');
    });

    test('disconnecting one Page leaves the other token intact', () async {
      await service.setFacebookPages([pageA, pageB]);
      await service.setFacebookPageTokenFor('a', 'token-a');
      await service.setFacebookPageTokenFor('b', 'token-b');
      await service.setFacebookActivePageId('a');
      await service.setFacebookPageId('a');
      await service.setFacebookPageName('Page A');

      await service.disconnectFacebookPage('a');

      expect(service.facebookPages, [pageB]);
      expect(service.facebookActivePageId, 'b');
      expect(service.facebookPageId, 'b');
      expect(await service.getFacebookPageTokenFor('a'), isNull);
      expect(await service.getFacebookPageTokenFor('b'), 'token-b');
    });

    test('full disconnect removes every per-page token', () async {
      await service.setFacebookPages([pageA, pageB]);
      await service.setFacebookPageTokenFor('a', 'token-a');
      await service.setFacebookPageTokenFor('b', 'token-b');
      await service.setFacebookActivePageId('a');
      await service.setFacebookPageToken('legacy-token');

      await service.disconnectFacebook();

      expect(service.facebookPages, isEmpty);
      expect(service.facebookActivePageId, isNull);
      expect(await service.getFacebookPageTokenFor('a'), isNull);
      expect(await service.getFacebookPageTokenFor('b'), isNull);
      expect(await service.getFacebookPageToken(), isNull);
    });

    test('legacy single Page migrates to a per-page token', () async {
      await service.setFacebookPageId('legacy');
      await service.setFacebookPageName('Legacy Page');
      await service.setFacebookPagePicture('https://example.com/l.png');
      await service.setFacebookPageToken('legacy-token');

      await service.migrateLegacyFacebookPage();

      expect(service.facebookPages.single.id, 'legacy');
      expect(service.facebookPages.single.name, 'Legacy Page');
      expect(service.facebookActivePageId, 'legacy');
      expect(await service.getFacebookPageTokenFor('legacy'), 'legacy-token');
      // Legacy identity keys stay readable for one release.
      expect(prefs.getString(AppConstants.keyFacebookPageId), 'legacy');
      expect(prefs.getString(AppConstants.keyFacebookPageName), 'Legacy Page');
    });

    test('migration is idempotent', () async {
      await service.setFacebookPageId('legacy');
      await service.setFacebookPageToken('legacy-token');
      await service.migrateLegacyFacebookPage();
      final pages = service.facebookPages;

      await service.migrateLegacyFacebookPage();
      expect(service.facebookPages, pages);
    });
  });
}
