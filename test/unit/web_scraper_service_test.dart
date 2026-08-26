import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';

void main() {
  group('WebScraperService', () {
    test('isUrl identifies valid http and https URLs', () {
      expect(
        WebScraperService.isUrl('https://theathletic.com/news/123'),
        isTrue,
      );
      expect(WebScraperService.isUrl('http://bbc.com/sport/football'), isTrue);
      expect(
        WebScraperService.isUrl(
          'https://twitter.com/FabrizioRomano/status/12345',
        ),
        isTrue,
      );
      expect(WebScraperService.isUrl('  https://espn.com/football   '), isTrue);
    });

    test('isUrl rejects non-URLs and invalid schemes', () {
      expect(
        WebScraperService.isUrl('Just a regular football update headline'),
        isFalse,
      );
      expect(
        WebScraperService.isUrl('ftp://ftp.example.com/file.txt'),
        isFalse,
      );
      expect(WebScraperService.isUrl('javascript:alert(1)'), isFalse);
      expect(WebScraperService.isUrl(''), isFalse);
      expect(WebScraperService.isUrl('jdt vs selangor'), isFalse);
    });
  });
}
