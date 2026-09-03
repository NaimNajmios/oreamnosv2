import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ErrorState with long message fits a 560px dialog', (
    tester,
  ) async {
    final longMessage = List.filled(
      20,
      'DioException [bad response]: status code of 400. ',
    ).join();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                  maxHeight: 560,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ErrorState(
                          title: 'Could Not Load Models',
                          message: longMessage,
                          retryLabel: 'Retry Fetch',
                          onRetry: () {},
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Could Not Load Models'), findsOneWidget);
    expect(find.text('Retry Fetch'), findsOneWidget);
  });

  testWidgets('ErrorState fits a narrow 280px dialog (device repro)', (
    tester,
  ) async {
    final longMessage = List.filled(
      8,
      'Gemini rejected the API key (HTTP 400). Check it in Settings. ',
    ).join();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 280,
                  maxHeight: 380,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ErrorState(
                          title: 'Could Not Load Models',
                          message: longMessage,
                          retryLabel: 'Retry Fetch',
                          onRetry: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Retry Fetch'), findsOneWidget);
  });

  testWidgets('ErrorState renders unbounded (scroll parent) without crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ErrorState(
              title: 'Generation Error',
              message: 'Something went wrong.',
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Generation Error'), findsOneWidget);
  });
}
