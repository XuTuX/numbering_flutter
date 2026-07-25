import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/widgets/formula_editor.dart';

void main() {
  testWidgets('time attack swaps the dragged and target digits',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaEditor(
            digits: const ['1', '2', '3', '4', '5'],
            availableOperators: const {'+', '-', '×', '÷', '='},
            accent: Colors.blue,
            isLandscape: true,
            visibleHints: const [],
            requiresEquals: true,
            allowDigitReordering: true,
            validateExpression: (_) => const ValidationResult.failure(''),
            onValidSubmission: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final source = find.byKey(const ValueKey('formula-digit-2'));
    final target = find.byKey(const ValueKey('formula-digit-0'));
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_digitAt(tester, 0), '3');
    expect(_digitAt(tester, 1), '2');
    expect(_digitAt(tester, 2), '1');
    expect(_digitAt(tester, 3), '4');
    expect(_digitAt(tester, 4), '5');
  });
}

String? _digitAt(WidgetTester tester, int index) {
  return tester
      .widget<Text>(find.byKey(ValueKey('formula-digit-text-$index')))
      .data;
}
