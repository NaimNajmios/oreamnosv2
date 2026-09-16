import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/free_tier_guard.dart';
import 'package:oreamnos/data/services/vision_image_prep.dart';
import 'package:oreamnos/domain/models/vision_mode.dart';
import 'package:oreamnos/domain/services/football_ocr_parser.dart';
import 'package:oreamnos/domain/services/vision_model_allowlist.dart';

void main() {
  group('VisionModelAllowlist (\$0 guarantee)', () {
    test('allows free flash-lite / scout / :free vision', () {
      expect(
        VisionModelAllowlist.isAllowed(
          AiProvider.gemini,
          'gemini-2.5-flash-lite',
        ),
        isTrue,
      );
      expect(
        VisionModelAllowlist.isAllowed(
          AiProvider.groq,
          'meta-llama/llama-4-scout-17b-16e-instruct',
        ),
        isTrue,
      );
      expect(
        VisionModelAllowlist.isAllowed(
          AiProvider.openRouter,
          'meta-llama/llama-3.2-11b-vision-instruct:free',
        ),
        isTrue,
      );
    });

    test('allows maverick + openrouter/free router', () {
      expect(
        VisionModelAllowlist.isAllowed(
          AiProvider.groq,
          'meta-llama/llama-4-maverick-17b-128e-instruct',
        ),
        isTrue,
      );
      expect(
        VisionModelAllowlist.isAllowed(
          AiProvider.openRouter,
          'openrouter/free',
        ),
        isTrue,
      );
      expect(
        VisionModelAllowlist.defaultFor(AiProvider.openRouter),
        'openrouter/free',
      );
    });

    test('blocks paid models', () {
      expect(
        VisionModelAllowlist.isAllowed(AiProvider.gemini, 'gemini-1.5-pro'),
        isFalse,
      );
      expect(
        VisionModelAllowlist.isAllowed(
          AiProvider.groq,
          'llama-3.3-70b-versatile',
        ),
        isFalse,
      );
      expect(
        () => VisionModelAllowlist.assertAllowed(
          AiProvider.gemini,
          'gemini-1.5-pro',
        ),
        throwsA(isA<Failure>()),
      );
    });

    test(
      'blocks retired/unpinned Gemini 3.6 (falls back to 2.5-flash-lite)',
      () {
        expect(
          VisionModelAllowlist.isAllowed(AiProvider.gemini, 'gemini-3.6-flash'),
          isFalse,
        );
        expect(
          VisionModelAllowlist.needsVisionDefault(
            AiProvider.gemini,
            'gemini-3.6-flash',
          ),
          isTrue,
        );
        expect(
          VisionModelAllowlist.candidatesFor(AiProvider.gemini).first,
          'gemini-2.5-flash-lite',
        );
      },
    );

    test('needsVisionDefault for text-only selections', () {
      expect(
        VisionModelAllowlist.needsVisionDefault(
          AiProvider.groq,
          'llama-3.3-70b-versatile',
        ),
        isTrue,
      );
      expect(
        VisionModelAllowlist.needsVisionDefault(
          AiProvider.gemini,
          'gemini-2.5-flash-lite',
        ),
        isFalse,
      );
      expect(
        VisionModelAllowlist.defaultFor(AiProvider.gemini),
        'gemini-2.5-flash-lite',
      );
    });
  });

  group('FreeTierGuard', () {
    test('skips provider at cap and finds next available', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final guard = FreeTierGuard(prefs);

      expect(guard.shouldSkip(AiProvider.gemini), isFalse);
      for (var i = 0; i < FreeTierGuard.dailyCaps['gemini']!; i++) {
        await guard.record(AiProvider.gemini);
      }
      expect(guard.shouldSkip(AiProvider.gemini), isTrue);
      expect(
        guard.firstAvailable([
          AiProvider.gemini,
          AiProvider.groq,
          AiProvider.openRouter,
        ]),
        AiProvider.groq,
      );
    });
  });

  group('VisionImagePrep', () {
    test('detectMimeType + dataUrl shape', () {
      expect(VisionImagePrep.detectMimeType('shot.JPG'), 'image/jpeg');
      expect(VisionImagePrep.detectMimeType('shot.png'), 'image/png');
      final url = VisionImagePrep.dataUrl(Uint8List.fromList([1, 2, 3]));
      expect(url.startsWith('data:image/png;base64,'), isTrue);
    });
  });

  group('VisionMode + OCR parser floor', () {
    test('fromString defaults to auto', () {
      expect(VisionMode.fromString(null), VisionMode.auto);
      expect(VisionMode.fromString('onDeviceOnly'), VisionMode.onDeviceOnly);
    });

    test('FootballOcrParser normalizes scores', () {
      final out = FootballOcrParser.formatForPrompt('Team A 2 - 1 Team B');
      expect(out.contains('2-1'), isTrue);
    });
  });
}
