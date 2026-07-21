import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexor/game/numbering/expression_engine.dart';
import 'package:hexor/game/numbering/numbering_models.dart';
import 'package:hexor/game/numbering/problem_generators.dart';

void main() {
  test('difficulty boundaries match solo rounds', () {
    expect(difficultyForRound(2), NumberingDifficulty.easy);
    expect(difficultyForRound(3), NumberingDifficulty.normal);
    expect(difficultyForRound(4), NumberingDifficulty.normal);
    expect(difficultyForRound(5), NumberingDifficulty.hard);
    expect(sequenceTermCountForRound(6), 7);
    expect(sequenceTermCountForRound(7), 8);
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

  test('sequence terms use the previous two and generated answer is unique',
      () {
    final random = Random(20);
    for (final count in [5, 6, 7, 8]) {
      for (var index = 0; index < 30; index++) {
        final problem = generateSequenceProblem(random, count);
        final terms = buildSequence(problem.startA, problem.startB, count);
        for (var term = 2; term < terms.length; term++) {
          expect(terms[term], terms[term - 2] + terms[term - 1]);
        }
        expect(
          sequenceCandidates(
            lastValue: problem.lastValue,
            termCount: count,
          ),
          [(problem.startA, problem.startB)],
        );
      }
    }
  });

  test('vault generator uses the exact multiset and reaches its target', () {
    final random = Random(30);
    for (final difficulty in NumberingDifficulty.values) {
      final expectedCount = switch (difficulty) {
        NumberingDifficulty.easy => 3,
        NumberingDifficulty.normal => 4,
        NumberingDifficulty.hard => 5,
      };
      for (var index = 0; index < 40; index++) {
        final problem = generateVaultProblem(random, difficulty);
        expect(problem.numbers, hasLength(expectedCount));
        expect(
          validateNumberVault(
            numbers: problem.numbers,
            target: problem.target,
            expression: problem.knownSolution,
          ).valid,
          isTrue,
          reason: problem.knownSolution,
        );
      }
    }
  });

  test('vault rejects missing, added, duplicated, and wrong-target input', () {
    const numbers = [2, 3, 4];
    for (final expression in ['2+3', '2+3+4+5', '2+2+4', '23+4']) {
      expect(
        validateNumberVault(
          numbers: numbers,
          target: 9,
          expression: expression,
        ).valid,
        isFalse,
        reason: expression,
      );
    }
    expect(
      validateNumberVault(
        numbers: numbers,
        target: 10,
        expression: '2+3+4',
      ).valid,
      isFalse,
    );
  });
}
