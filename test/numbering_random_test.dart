import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';

void main() {
  group('Time Attack equation', () {
    test('uses the shared equality value as the score', () {
      final result = validateReorderableEquality(
        digitString: '123321',
        expression: '1×2×3=3×2×1',
      );

      expect(result.valid, isTrue);
      expect(result.value, 6);
    });

    test('requires exactly one equals sign', () {
      final result = validateReorderableEquality(
        digitString: '123321',
        expression: '1+2+3+3+2+1',
      );

      expect(result.valid, isFalse);
      expect(result.message, '등호를 정확히 하나 사용해야 합니다.');
    });

    test('allows the supplied digits to be reordered', () {
      final result = validateReorderableEquality(
        digitString: '123321',
        expression: '3×2×1=1×2×3',
      );

      expect(result.valid, isTrue);
      expect(result.value, 6);
    });

    test('supports division equations after reordering digits', () {
      final result = validateReorderableEquality(
        digitString: '824822',
        expression: '8÷2+4=8+2-2',
      );

      expect(result.valid, isTrue);
      expect(result.value, 8);
    });

    test('rejects digits outside the supplied multiset', () {
      final result = validateReorderableEquality(
        digitString: '123321',
        expression: '3×2×1=1×2×4',
      );

      expect(result.valid, isFalse);
      expect(result.message, '주어진 6개의 숫자만 사용할 수 있습니다.');
    });
  });
}
