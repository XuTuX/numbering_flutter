import 'package:flutter_test/flutter_test.dart';
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
}
