import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/config/routes/app_router.dart';

void main() {
  group('RoutePaths.forWidgetUri', () {
    test('maps every documented widget host', () {
      expect(
        RoutePaths.forWidgetUri(Uri.parse('oreamnos://scheduled')),
        '${RoutePaths.facebookHistory}?tab=scheduled',
      );
      expect(
        RoutePaths.forWidgetUri(Uri.parse('oreamnos://usage')),
        RoutePaths.usage,
      );
      expect(
        RoutePaths.forWidgetUri(Uri.parse('oreamnos://compose')),
        RoutePaths.facebookCompose,
      );
      expect(
        RoutePaths.forWidgetUri(Uri.parse('oreamnos://publish')),
        RoutePaths.publish,
      );
      expect(
        RoutePaths.forWidgetUri(Uri.parse('oreamnos://generate')),
        RoutePaths.generate,
      );
      expect(
        RoutePaths.forWidgetUri(
          Uri.parse('oreamnos://calendar?date=2026-11-15'),
        ),
        '${RoutePaths.facebookCalendar}?date=2026-11-15',
      );
    });

    test('calendar ignores a malformed date instead of throwing', () {
      expect(
        RoutePaths.forWidgetUri(
          Uri.parse('oreamnos://calendar?date=15-11-2026'),
        ),
        RoutePaths.facebookCalendar,
      );
      expect(
        RoutePaths.forWidgetUri(
          Uri.parse('oreamnos://calendar?date=2026-02-31'),
        ),
        RoutePaths.facebookCalendar,
      );
      expect(
        RoutePaths.forWidgetUri(Uri.parse('oreamnos://calendar')),
        RoutePaths.facebookCalendar,
      );
    });

    test('accepts a bare path as well as a host', () {
      expect(
        RoutePaths.forWidgetUri(Uri.parse('scheduled')),
        '${RoutePaths.facebookHistory}?tab=scheduled',
      );
      expect(RoutePaths.forWidgetUri(Uri.parse('/usage')), RoutePaths.usage);
    });

    test('ignores unknown or missing URIs', () {
      expect(RoutePaths.forWidgetUri(Uri.parse('oreamnos://settings')), isNull);
      expect(RoutePaths.forWidgetUri(Uri.parse('https://example.com')), isNull);
      expect(RoutePaths.forWidgetUri(null), isNull);
    });
  });
}
