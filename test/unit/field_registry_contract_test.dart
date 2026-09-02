import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_field_registry.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/card_slot.dart';

void main() {
  group('Field Registry Contract Tests', () {
    test('All 17 templates have registered fields', () {
      for (final template in CardTemplate.all) {
        final fields = CardFieldRegistry.fieldsFor(template);
        expect(
          fields.isNotEmpty,
          isTrue,
          reason: 'Template ${template.name} has empty fields in registry',
        );

        for (final field in fields) {
          expect(field.key.isNotEmpty, isTrue);
          expect(field.label.isNotEmpty, isTrue);
          expect(field.maxChars, greaterThanOrEqualTo(0));
          expect(
            ['primary', 'secondary', 'optional'].contains(field.group),
            isTrue,
            reason: 'Field ${field.key} has invalid group ${field.group}',
          );
        }
      }
    });

    test('CardPromptManager prompts contain all registry field keys for each template', () {
      for (final template in CardTemplate.all) {
        final fields = CardFieldRegistry.fieldsFor(template);
        final prompt = CardPromptManager.buildPrompt(
          template,
          'Sample Article',
          false,
        );

        for (final field in fields) {
          expect(
            prompt,
            contains('"${field.key}":'),
            reason:
                'Prompt for ${template.name} is missing registry key "${field.key}"',
          );
        }
        expect(
          prompt,
          contains('"template_intent": "${template.templateIntent}"'),
          reason: 'Prompt for ${template.name} is missing template_intent',
        );
      }
    });
  });

  group('CardSlot Widget Tests', () {
    testWidgets('renders child when value is valid and non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardSlot(
              value: 'Erling Haaland',
              fieldKey: 'playerName',
              child: Text('Erling Haaland'),
            ),
          ),
        ),
      );

      expect(find.text('Erling Haaland'), findsOneWidget);
    });

    testWidgets('hides child when value is empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardSlot(
              value: '',
              fieldKey: 'playerName',
              child: Text('Erling Haaland'),
            ),
          ),
        ),
      );

      expect(find.text('Erling Haaland'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('hides child when value is N/A placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardSlot(
              value: 'N/A',
              fieldKey: 'playerName',
              child: Text('Erling Haaland'),
            ),
          ),
        ),
      );

      expect(find.text('Erling Haaland'), findsNothing);
    });

    testWidgets(
      'renders placeholder when value is empty and placeholder is provided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CardSlot(
                value: '',
                fieldKey: 'playerName',
                emptyPlaceholder: Text('Tap to add player'),
                child: Text('Erling Haaland'),
              ),
            ),
          ),
        );

        expect(find.text('Erling Haaland'), findsNothing);
        expect(find.text('Tap to add player'), findsOneWidget);
      },
    );
  });
}
