import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';

void main() {
  group('division and evaluation', () {
    test('evaluates division with multiplication and addition precedence', () {
      expect(evaluateIntegerExpression('8÷2').value, 4);
      expect(evaluateIntegerExpression('2+12÷3×2').value, 10);
    });

    test('evaluates parentheses correctly', () {
      expect(evaluateIntegerExpression('(2+3)×4').value, 20);
      expect(evaluateIntegerExpression('12÷(2+2)').value, 3);
    });

    test('rejects division by zero and non-integer division', () {
      expect(evaluateIntegerExpression('8÷0').valid, isFalse);
      expect(evaluateIntegerExpression('8÷3').valid, isFalse);
    });

    test('validates division formulas', () {
      final result = validateLevelFormula(
        digitString: '824',
        expression: '8÷2=4',
        availableOperators: const {'+', '-', '×', '÷', '='},
      );
      expect(result.valid, isTrue);
      expect(result.value, 4);
    });

    test('rejects division when operator is not available', () {
      final result = validateLevelFormula(
        digitString: '824',
        expression: '8÷2=4',
        availableOperators: const {'+', '-', '×', '='},
      );
      expect(result.valid, isFalse);
      expect(result.message, '÷ 기호는 이 레벨에서 사용할 수 없습니다.');
    });
  });
}
