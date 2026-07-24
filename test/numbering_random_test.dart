import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/numbering_random.dart';

void main() {
  group('official daily Numbering puzzle', () {
    test('the same seed always produces the same eight digits', () {
      expect(generateDailyNumberingPuzzle(123456), '27297772');
      expect(generateDailyNumberingPuzzle(123456), '27297772');
    });

    test('different seeds produce different puzzles', () {
      expect(
        generateDailyNumberingPuzzle(123456),
        isNot(generateDailyNumberingPuzzle(123457)),
      );
    });

    test('zero seed is deterministic and every digit is in 1 through 9', () {
      final puzzle = generateDailyNumberingPuzzle(0);
      expect(puzzle, '75574636');
      expect(puzzle, hasLength(8));
      expect(puzzle, matches(RegExp(r'^[1-9]{8}$')));
    });
  });

  group('official daily equation', () {
    test('uses the shared equality value as the score', () {
      final result = validateDailyPuzzleFormula(
        digitString: '123321',
        expression: '1×2×3=3×2×1',
      );

      expect(result.valid, isTrue);
      expect(result.value, 6);
    });

    test('requires exactly one equals sign', () {
      final result = validateDailyPuzzleFormula(
        digitString: '123321',
        expression: '1+2+3+3+2+1',
      );

      expect(result.valid, isFalse);
      expect(result.message, '등호를 정확히 하나 사용해야 합니다.');
    });

    test('allows the supplied digits to be reordered', () {
      final result = validateDailyPuzzleFormula(
        digitString: '123321',
        expression: '3×2×1=1×2×3',
      );

      expect(result.valid, isTrue);
      expect(result.value, 6);
    });

    test('supports exponent equations after reordering digits', () {
      final result = validateDailyPuzzleFormula(
        digitString: '81243126',
        expression: '2^3+4+1-1=8+6-2',
      );

      expect(result.valid, isTrue);
      expect(result.value, 12);
    });

    test('rejects digits outside the supplied multiset', () {
      final result = validateDailyPuzzleFormula(
        digitString: '123321',
        expression: '3×2×1=1×2×4',
      );

      expect(result.valid, isFalse);
      expect(result.message, '주어진 8개의 숫자만 사용할 수 있습니다.');
    });
  });
}
