import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/facebook_story_title.dart';

void main() {
  test('prefers an explicit headline', () {
    expect(
      FacebookStoryTitle.extract(
        text: 'Full caption here\nSecond line',
        headline: 'JDT 4 - 1 Terengganu',
      ),
      'JDT 4 - 1 Terengganu',
    );
  });

  test('falls back to the first meaningful line', () {
    expect(
      FacebookStoryTitle.extract(
        text: '\n\n**FT: JDT wins** #FAM\nMore details',
      ),
      'FT: JDT wins',
    );
  });

  test('strips markdown links, images, URLs and hashtags', () {
    expect(
      FacebookStoryTitle.extract(
        text: '![alt](x) [Match report](https://x.test) #FAM',
      ),
      'Match report',
    );
  });

  test('truncates at a word boundary with an ellipsis', () {
    final title = FacebookStoryTitle.extract(text: 'word ' * 50);
    expect(title.length, lessThanOrEqualTo(101));
    expect(title, endsWith('…'));
  });

  test('empty input returns empty', () {
    expect(FacebookStoryTitle.extract(text: '   \n #FAM'), isEmpty);
  });
}
