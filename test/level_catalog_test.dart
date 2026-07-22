import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';

void main() {
  test('catalog contains 160 ordered, playable levels', () {
    expect(LevelCatalog.all, hasLength(160));
    expect(
      LevelCatalog.all.map((level) => level.id),
      orderedEquals(List.generate(160, (index) => index + 1)),
    );
    expect(
      LevelCatalog.all.map((level) => level.officialAnswer).toSet(),
      hasLength(160),
      reason: 'Each fixed level must have a distinct official construction.',
    );

    for (final level in LevelCatalog.all) {
      if (level.perfectAnswer == null) {
        expect(
          level.digits.length,
          inInclusiveRange(_minimumDigits(level.id), _maximumDigits(level.id)),
          reason: 'LEVEL ${level.id} digit count',
        );
      }
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

  test('level map resolves to the pack containing the current level', () {
    expect(levelPackFor(1).name, 'Seoul');
    expect(levelPackFor(20).name, 'Seoul');
    expect(levelPackFor(21).name, 'Tokyo');
    expect(levelPackFor(80).name, 'New York');
    expect(levelPackFor(160).name, 'Paris');
  });
}

int _minimumDigits(int id) {
  if (id <= 20) return id <= 10 ? 4 : 5;
  if (id <= 40) return id <= 30 ? 5 : 6;
  if (id <= 80) return id <= 60 ? 6 : 7;
  if (id <= 120) return id <= 100 ? 7 : 8;
  return id <= 140 ? 8 : 9;
}

int _maximumDigits(int id) {
  return _minimumDigits(id);
}
