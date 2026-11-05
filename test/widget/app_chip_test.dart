import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';

ThemeData _darkTheme() {
  const scheme = ColorScheme.dark(
    primary: Color(0xFF38BDF8),
    onPrimary: Colors.black,
    primaryContainer: Color(0xFF0C4A6E),
    onPrimaryContainer: Colors.white,
    surface: Color(0xFF1A1A1A),
    onSurface: Color(0xFFF5F5F5),
    outline: Color(0xFF2E2E2E),
  );
  return ThemeData(useMaterial3: true, colorScheme: scheme);
}

void main() {
  testWidgets('selected chip uses onPrimaryContainer for contrast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _darkTheme(),
        home: Scaffold(
          body: AppChip(label: 'Title', selected: true, onTap: () {}),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Title'));
    expect(text.style?.color, Colors.white);
    expect(text.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('disabled chip is visually muted', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _darkTheme(),
        home: const Scaffold(
          body: AppChip(label: 'Uppercase', selected: false),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Uppercase'));
    expect(text.style?.color?.a, closeTo(0.45, 0.01));
  });

  testWidgets('custom selected color falls back to onPrimary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _darkTheme(),
        home: Scaffold(
          body: AppChip(
            label: 'Error',
            selected: true,
            selectedColor: Colors.red,
            onTap: () {},
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Error'));
    expect(text.style?.color, Colors.black);
  });
}
