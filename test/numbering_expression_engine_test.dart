import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';

void main() {
  group('build and evaluate expressions', () {
    test('assembles adjacent digits and operators in order', () {
      final expression = assembleInlineExpression(
        digits: const ['1', '9', '1', '4', '5'],
        operators: const [
          null,
          InlineOperator.equals,
          null,
          InlineOperator.add,
        ],
      );
      expect(expression, '19=14+5');
    });

    test('applies precedence and parentheses', () {
      expect(evaluateIntegerExpression('12 + 3 × 4').value, 24);
      expect(evaluateIntegerExpression('(12 + 3) × 4').value, 60);
      expect(evaluateIntegerExpression('20 - 6 - 3').value, 11);
    });

    test('rejects unsafe or non-integer syntax', () {
      for (final expression in [
        '5 ÷ 2',
        '1 ÷ 0',
        '-1 + 2',
        '1.5 + 2',
        '(1 + 2',
        '2(3 + 4)',
        '()',
      ]) {
        expect(
          evaluateIntegerExpression(expression).valid,
          isFalse,
          reason: expression,
        );
      }
    });
  });

  group('formula workshop validation', () {
    test('accepts a valid equation', () {
      final result = validateFormulaWorkshop(
        digitString: '19145',
        expression: '19 = 14 + 5',
      );
      expect(result.valid, isTrue);
      expect(result.value, 19);
    });

    test('rejects missing, added, or reordered digits', () {
      for (final expression in ['19=14', '19=14+55', '91=14+5']) {
        expect(
          validateFormulaWorkshop(
            digitString: '19145',
            expression: expression,
          ).valid,
          isFalse,
          reason: expression,
        );
      }
    });

    test('distinguishes invalid equals layouts and unequal values', () {
      expect(
        validateFormulaWorkshop(
          digitString: '123',
          expression: '1+2+3',
        ).message,
        contains('정확히 하나'),
      );
      expect(
        validateFormulaWorkshop(
          digitString: '123',
          expression: '1=2=3',
        ).message,
        contains('정확히 하나'),
      );
      expect(
        validateFormulaWorkshop(
          digitString: '123',
          expression: '=1+23',
        ).message,
        contains('양쪽'),
      );
      expect(
        validateFormulaWorkshop(
          digitString: '123',
          expression: '1+2=3',
        ).valid,
        isTrue,
      );
      expect(
        validateFormulaWorkshop(
          digitString: '124',
          expression: '1+2=4',
        ).message,
        contains('다릅니다'),
      );
    });
  });

  group('parenthesis ranges', () {
    const outer = ParenthesisRange(
      id: 'outer',
      startDigitIndex: 0,
      endDigitIndex: 3,
    );

    test('rejects duplicate and crossing ranges', () {
      expect(
        validateParenthesisRange(
          digitCount: 5,
          candidate: outer,
          existing: const [outer],
        ).valid,
        isFalse,
      );
      expect(
        validateParenthesisRange(
          digitCount: 5,
          candidate: const ParenthesisRange(
            id: 'crossing',
            startDigitIndex: 2,
            endDigitIndex: 4,
          ),
          existing: const [outer],
        ).valid,
        isFalse,
      );
    });

    test('allows nested and separated ranges', () {
      expect(
        validateParenthesisRange(
          digitCount: 6,
          candidate: const ParenthesisRange(
            id: 'nested',
            startDigitIndex: 1,
            endDigitIndex: 2,
          ),
          existing: const [outer],
        ).valid,
        isTrue,
      );
      expect(
        validateParenthesisRange(
          digitCount: 6,
          candidate: const ParenthesisRange(
            id: 'separate',
            startDigitIndex: 4,
            endDigitIndex: 5,
          ),
          existing: const [outer],
        ).valid,
        isTrue,
      );
    });
  });
}
