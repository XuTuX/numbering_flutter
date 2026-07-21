import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
import 'package:numbering/game/numbering/level_models.dart';

void main() {
  test('catalog contains 200 ordered, playable levels', () {
    expect(LevelCatalog.all, hasLength(200));
    expect(
      LevelCatalog.all.map((level) => level.id),
      orderedEquals(List.generate(200, (index) => index + 1)),
    );
    expect(
      LevelCatalog.all.map((level) => level.officialAnswer).toSet(),
      hasLength(200),
      reason: 'Each fixed level must have a distinct official construction.',
    );

    for (final level in LevelCatalog.all) {
      expect(
        level.digits.length,
        inInclusiveRange(_minimumDigits(level.id), _maximumDigits(level.id)),
        reason: 'LEVEL ${level.id} digit count',
      );
      expect(level.minimumScore, lessThanOrEqualTo(level.targetScore));
      expect(level.availableOperators, contains('='));

      final result = validateLevelFormula(
        digitString: level.digitString,
        expression: level.officialAnswer,
        availableOperators: level.availableOperators,
      );
      expect(result.valid, isTrue,
          reason: 'LEVEL ${level.id}: ${result.message}');
      expect(result.value, level.targetScore,
          reason: 'LEVEL ${level.id} target score');

      if (level.id < 100) {
        expect(
          RegExp(r'\d{2,}×\d{2,}').hasMatch(level.officialAnswer),
          isFalse,
          reason: 'LEVEL ${level.id} multiplication limit',
        );
      }
    }
  });

  test('declared perfect solutions are valid and beat their target', () {
    final levelsWithPerfect =
        LevelCatalog.all.where((level) => level.perfectAnswer != null).toList();
    expect(levelsWithPerfect.length, greaterThanOrEqualTo(5));

    for (final level in levelsWithPerfect) {
      final result = validateLevelFormula(
        digitString: level.digitString,
        expression: level.perfectAnswer!,
        availableOperators: level.availableOperators,
      );
      expect(result.valid, isTrue,
          reason: 'LEVEL ${level.id}: ${result.message}');
      expect(result.value, level.possiblePerfectScore);
      expect(result.value, greaterThan(level.targetScore));
      expect(evaluateLevelScore(level, result.value!).perfect, isTrue);
    }
  });

  test('score evaluation follows fail, one-star, three-star, perfect order',
      () {
    final level = LevelCatalog.byId(50);
    expect(evaluateLevelScore(level, level.minimumScore - 1).cleared, isFalse);
    if (level.minimumScore < level.targetScore) {
      expect(evaluateLevelScore(level, level.minimumScore).stars, 1);
    }
    expect(evaluateLevelScore(level, level.targetScore).stars, 3);
    expect(evaluateLevelScore(level, level.targetScore).perfect, isFalse);
    expect(evaluateLevelScore(level, level.targetScore + 1).perfect, isTrue);
  });
}

int _minimumDigits(int id) {
  if (id <= 10) return 4;
  if (id <= 30) return 5;
  if (id <= 70) return 6;
  if (id <= 110) return 7;
  return 8;
}

int _maximumDigits(int id) {
  if (id <= 10) return 5;
  if (id <= 30) return 6;
  if (id <= 70) return 7;
  if (id <= 110) return 8;
  if (id <= 170) return 8;
  return 9;
}
