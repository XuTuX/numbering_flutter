import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';

void main() {
  group('exponent evaluation', () {
    test('evaluates exponent before multiplication and addition', () {
      expect(evaluateIntegerExpression('2^3').value, 8);
      expect(evaluateIntegerExpression('2+3^2×2').value, 20);
    });

    test('evaluates chained exponents from right to left', () {
      expect(evaluateIntegerExpression('2^3^2').value, 512);
      expect(evaluateIntegerExpression('(2^3)^2').value, 64);
    });

    test('rejects non-integer and oversized exponent results', () {
      expect(evaluateIntegerExpression('2^(3-4)').valid, isFalse);
      expect(evaluateIntegerExpression('0^0').valid, isFalse);
      expect(evaluateIntegerExpression('9^10').valid, isFalse);
    });

    test('validates the Sydney introduction equation', () {
      final result = validateLevelFormula(
        digitString: '238',
        expression: '2^3=8',
        availableOperators: const {'+', '-', '×', '÷', '^', '='},
      );
      expect(result.valid, isTrue);
      expect(result.value, 8);
    });

    test('rejects exponent before it is unlocked', () {
      final result = validateLevelFormula(
        digitString: '238',
        expression: '2^3=8',
        availableOperators: const {'+', '-', '×', '÷', '='},
      );
      expect(result.valid, isFalse);
      expect(result.message, '^ 기호는 이 레벨에서 사용할 수 없습니다.');
    });
  });
}
