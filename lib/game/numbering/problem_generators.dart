import 'dart:math';

import 'numbering_models.dart';

class FormulaProblem {
  const FormulaProblem({
    required this.digitString,
    required this.knownSolution,
  });

  final String digitString;
  final String knownSolution;

  List<String> get digits => digitString.split('');
}

FormulaProblem generateFormulaProblem(
  Random random,
  NumberingDifficulty difficulty,
) {
  switch (difficulty) {
    case NumberingDifficulty.easy:
      final left = 2 + random.nextInt(8);
      final right = 2 + random.nextInt(8);
      final result = left + right;
      return FormulaProblem(
        digitString: '$left$right$result',
        knownSolution: '$left+$right=$result',
      );
    case NumberingDifficulty.normal:
      final left = 10 + random.nextInt(40);
      final right = 2 + random.nextInt(8);
      final result = left + right;
      return FormulaProblem(
        digitString: '$left$right$result',
        knownSolution: '$left+$right=$result',
      );
    case NumberingDifficulty.hard:
      final left = 10 + random.nextInt(30);
      final right = 4 + random.nextInt(12);
      final tail = 2 + random.nextInt(8);
      final other = left + right - tail;
      return FormulaProblem(
        digitString: '$left$right$other$tail',
        knownSolution: '$left+$right=$other+$tail',
      );
  }
}

class SequenceProblem {
  const SequenceProblem({
    required this.termCount,
    required this.lastValue,
    required this.startA,
    required this.startB,
  });

  final int termCount;
  final int lastValue;
  final int startA;
  final int startB;
}

List<int> buildSequence(int startA, int startB, int termCount) {
  final terms = <int>[startA, startB];
  while (terms.length < termCount) {
    terms.add(terms[terms.length - 2] + terms.last);
  }
  return terms.take(termCount).toList();
}

List<(int, int)> sequenceCandidates({
  required int lastValue,
  required int termCount,
}) {
  final candidates = <(int, int)>[];
  for (var a = 1; a <= 9; a++) {
    for (var b = 1; b <= 9; b++) {
      if (buildSequence(a, b, termCount).last == lastValue) {
        candidates.add((a, b));
      }
    }
  }
  return candidates;
}

SequenceProblem generateSequenceProblem(Random random, int termCount) {
  final unique = <SequenceProblem>[];
  for (var a = 1; a <= 9; a++) {
    for (var b = 1; b <= 9; b++) {
      final last = buildSequence(a, b, termCount).last;
      if (sequenceCandidates(lastValue: last, termCount: termCount).length ==
          1) {
        unique.add(SequenceProblem(
          termCount: termCount,
          lastValue: last,
          startA: a,
          startB: b,
        ));
      }
    }
  }
  if (unique.isEmpty) {
    throw StateError('고유한 수열 문제를 만들 수 없습니다.');
  }
  return unique[random.nextInt(unique.length)];
}

class VaultProblem {
  const VaultProblem({
    required this.numbers,
    required this.target,
    required this.knownSolution,
  });

  final List<int> numbers;
  final int target;
  final String knownSolution;
}

class _VaultExpression {
  const _VaultExpression(this.value, this.text);

  final int value;
  final String text;
}

VaultProblem generateVaultProblem(
  Random random,
  NumberingDifficulty difficulty,
) {
  final count = switch (difficulty) {
    NumberingDifficulty.easy => 3,
    NumberingDifficulty.normal => 4,
    NumberingDifficulty.hard => 5,
  };

  for (var attempt = 0; attempt < 200; attempt++) {
    final numbers = List.generate(count, (_) => 2 + random.nextInt(8));
    final expressions =
        numbers.map((number) => _VaultExpression(number, '$number')).toList();
    while (expressions.length > 1) {
      final firstIndex = random.nextInt(expressions.length);
      final first = expressions.removeAt(firstIndex);
      final secondIndex = random.nextInt(expressions.length);
      final second = expressions.removeAt(secondIndex);
      final candidates = <_VaultExpression>[
        _VaultExpression(
          first.value + second.value,
          '(${first.text}+${second.text})',
        ),
        _VaultExpression(
          first.value * second.value,
          '(${first.text}×${second.text})',
        ),
        if (first.value != second.value)
          _VaultExpression(
            (first.value - second.value).abs(),
            first.value > second.value
                ? '(${first.text}-${second.text})'
                : '(${second.text}-${first.text})',
          ),
        if (second.value != 0 && first.value % second.value == 0)
          _VaultExpression(
            first.value ~/ second.value,
            '(${first.text}÷${second.text})',
          ),
        if (first.value != 0 && second.value % first.value == 0)
          _VaultExpression(
            second.value ~/ first.value,
            '(${second.text}÷${first.text})',
          ),
      ];
      expressions.add(candidates[random.nextInt(candidates.length)]);
    }
    final result = expressions.single;
    final sum = numbers.fold(0, (total, number) => total + number);
    if (result.value > 0 && result.value <= 500 && result.value != sum) {
      numbers.shuffle(random);
      return VaultProblem(
        numbers: numbers,
        target: result.value,
        knownSolution: result.text,
      );
    }
  }
  throw StateError('숫자 금고 문제 생성에 실패했습니다.');
}
