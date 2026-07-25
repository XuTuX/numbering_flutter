import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/widgets/formula_editor.dart';
import 'package:numbering/theme/app_colors.dart';

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

  testWidgets('wrong equality flashes without showing an error message',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaEditor(
            digits: const ['1', '2'],
            availableOperators: const {'='},
            accent: Colors.blue,
            isLandscape: true,
            visibleHints: const [],
            requiresEquals: true,
            validateExpression: (_) => const ValidationResult.failure('wrong'),
            onValidSubmission: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final equals = find.byKey(const ValueKey('operator-drag-='));
    final rightDigit = find.byKey(const ValueKey('formula-digit-1'));
    final gesture = await tester.startGesture(tester.getCenter(equals));
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(rightDigit) + const Offset(0, 44.2),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('='), findsNWidgets(2));
    expect(find.byKey(const ValueKey('wrong-answer-flash')), findsOneWidget);
    final digitStyle = tester
        .widget<AnimatedDefaultTextStyle>(
          find.descendant(
            of: find.byKey(const ValueKey('formula-digit-0')),
            matching: find.byType(AnimatedDefaultTextStyle),
          ),
        )
        .style;
    expect(digitStyle.color, isNot(AppColors.ink));
    expect(find.text('정답이 아닙니다.'), findsNothing);

    await tester.pump(const Duration(milliseconds: 280));
    final heldDigitStyle = tester
        .widget<AnimatedDefaultTextStyle>(
          find.descendant(
            of: find.byKey(const ValueKey('formula-digit-0')),
            matching: find.byType(AnimatedDefaultTextStyle),
          ),
        )
        .style;
    expect(heldDigitStyle.color, AppColors.wrongAnswer);

    await tester.pumpAndSettle();
    final settledDigitStyle = tester
        .widget<AnimatedDefaultTextStyle>(
          find.descendant(
            of: find.byKey(const ValueKey('formula-digit-0')),
            matching: find.byType(AnimatedDefaultTextStyle),
          ),
        )
        .style;
    expect(settledDigitStyle.color, AppColors.ink);
    expect(tester.takeException(), isNull);
  });
}

String? _digitAt(WidgetTester tester, int index) {
  return tester
      .widget<Text>(find.byKey(ValueKey('formula-digit-text-$index')))
      .data;
}
