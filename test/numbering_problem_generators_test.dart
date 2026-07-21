import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/problem_generators.dart';

void main() {
  test('difficulty boundaries match solo rounds', () {
    expect(difficultyForRound(2), NumberingDifficulty.easy);
    expect(difficultyForRound(3), NumberingDifficulty.normal);
    expect(difficultyForRound(4), NumberingDifficulty.normal);
    expect(difficultyForRound(5), NumberingDifficulty.hard);
  });

  test('formula generator always emits a valid known solution', () {
    final random = Random(10);
    for (final difficulty in NumberingDifficulty.values) {
      for (var index = 0; index < 30; index++) {
        final problem = generateFormulaProblem(random, difficulty);
        expect(
          validateFormulaWorkshop(
            digitString: problem.digitString,
            expression: problem.knownSolution,
          ).valid,
          isTrue,
          reason: problem.knownSolution,
        );
      }
    }
  });
}
