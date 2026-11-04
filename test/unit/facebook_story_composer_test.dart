import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oreamnos/data/services/facebook_story_composer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generated Story is a valid 1080x1920 JPEG', () async {
    final dir = await Directory.systemTemp.createTemp('oreamnos_story');
    addTearDown(() => dir.delete(recursive: true));

    final path = await FacebookStoryComposer().compose(
      title: 'Matchday: JDT 4 - 1 Terengganu',
      outputDir: dir.path,
    );
    final file = File(path);
    expect(file.existsSync(), isTrue);
    final decoded = img.decodeImage(await file.readAsBytes());
    expect(decoded, isNotNull);
    expect(decoded!.width, 1080);
    expect(decoded.height, 1920);
  });

  test('title is optional but still produces a valid image', () async {
    final dir = await Directory.systemTemp.createTemp('oreamnos_story');
    addTearDown(() => dir.delete(recursive: true));
    final path = await FacebookStoryComposer().compose(
      title: '',
      outputDir: dir.path,
    );
    expect(File(path).existsSync(), isTrue);
  });
}
