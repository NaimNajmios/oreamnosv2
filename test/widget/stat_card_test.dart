import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/app_theme.dart';
import 'package:oreamnos/ui/core/widgets/stat_card.dart';

void main() {
  testWidgets('value stays on one line in a narrow card at 200% text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'TOTAL TOKENS',
                    value: '123,456,789',
                    subtitle: 'all time',
                  ),
                ),
                const Expanded(
                  child: StatCard(title: 'SUCCESS', value: '100%'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('123,456,789'), findsOneWidget);
    expect(find.text('all time'), findsOneWidget);
  });
}
