import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/utils/version_compare.dart';

void main() {
  group('compareVersions', () {
    test('orders numeric parts, not strings', () {
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('2.0.0', '10.0.0'), lessThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    });

    test('ignores a v prefix and build metadata', () {
      expect(compareVersions('v1.2.0', '1.2.0'), 0);
      expect(compareVersions('1.2.0+5', '1.2.0'), 0);
      expect(compareVersions('V1.2.0+9', 'v1.2.0'), 0);
    });

    test('treats missing parts as zero', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('a pre-release is older than the final release', () {
      expect(compareVersions('1.2.0-beta.1', '1.2.0'), lessThan(0));
      expect(compareVersions('1.2.0', '1.2.0-beta.1'), greaterThan(0));
    });

    test('orders prerelease identifiers', () {
      expect(compareVersions('1.2.0-beta.1', '1.2.0-beta.2'), lessThan(0));
      expect(compareVersions('1.2.0-beta.9', '1.2.0-beta.10'), lessThan(0));
      expect(compareVersions('1.2.0-alpha', '1.2.0-beta'), lessThan(0));
      expect(compareVersions('1.2.0-beta', '1.2.0-beta.1'), lessThan(0));
      expect(compareVersions('1.2.0-beta.1', '1.2.0-beta.1'), 0);
    });

    test('never throws on garbage and degrades to zero', () {
      expect(() => compareVersions('not-a-version', '1.0.0'), returnsNormally);
      // The non-numeric core counts as 0; the leftover suffix reads as a
      // prerelease, so it sorts below an equal core.
      expect(compareVersions('not-a-version', '0.0.0'), lessThan(0));
      expect(() => compareVersions('', ''), returnsNormally);
      expect(compareVersions('', '0.0.0'), 0);
      expect(compareVersions('...', '0'), 0);
      expect(compareVersions('v', '0.0.0'), 0);
    });
  });

  group('isNewerVersion', () {
    test('is strict', () {
      expect(isNewerVersion('1.2.0', '1.1.9'), isTrue);
      expect(isNewerVersion('1.2.0', '1.2.0'), isFalse);
      expect(isNewerVersion('1.2.0-beta.1', '1.2.0'), isFalse);
      expect(isNewerVersion('v1.3.0', '1.2.9'), isTrue);
    });
  });

  group('stripVersionPrefix', () {
    test('normalizes tag-shaped strings', () {
      expect(stripVersionPrefix('v1.2.3'), '1.2.3');
      expect(stripVersionPrefix('  V1.2.3  '), '1.2.3');
      expect(stripVersionPrefix('1.2.3+42'), '1.2.3');
      expect(stripVersionPrefix('1.2.3-beta.1+42'), '1.2.3-beta.1');
    });
  });
}
