import 'dart:math';

import 'level_models.dart';

abstract final class LevelCatalog {
  static final List<LevelData> all = List<LevelData>.unmodifiable(
    List.generate(200, (index) => _buildLevel(index + 1)),
  );

  static LevelData byId(int id) {
    if (id < 1 || id > all.length) {
      throw RangeError.range(id, 1, all.length, 'id');
    }
    return all[id - 1];
  }
}

LevelData _buildLevel(int id) {
  final handcrafted = _handcraftedLevels[id];
  if (handcrafted != null) return handcrafted;

  final digitCount = _digitCountFor(id);
  final difficulty = _difficultyFor(id);
  final allowed = <String>{'+', '-', '='};
  if (id >= 11) allowed.add('×');
  if (id >= 71) allowed.add('÷');

  final random = Random(id * 7919 + 20260721);
  for (var attempt = 0; attempt < 1200; attempt++) {
    final leftLeaves = digitCount ~/ 2;
    final rightLeaves = digitCount - leftLeaves;
    final maxTarget = min(leftLeaves, rightLeaves) * (id < 11 ? 7 : 9);
    final target = 3 + random.nextInt(max(2, maxTarget - 2));
    final left = _compose(
      target: target,
      leaves: leftLeaves,
      allowed: allowed,
      random: random,
      depth: 0,
    );
    final right = _compose(
      target: target,
      leaves: rightLeaves,
      allowed: allowed,
      random: random,
      depth: 0,
    );
    if (left == null || right == null || left.text == right.text) continue;

    final answer = '${left.text}=${right.text}';
    final digits = answer.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != digitCount) continue;
    if (id < 100 && RegExp(r'\d{2,}×\d{2,}').hasMatch(answer)) continue;

    final usedOperators = <String>{
      for (final match in RegExp(r'[+\-×÷]').allMatches(answer))
        match.group(0)!,
    };
    final operatorHint = _operatorHint(usedOperators);
    final delta = max(2, target ~/ (id < 31 ? 4 : 3));
    return LevelData(
      id: id,
      digitString: digits,
      availableOperators: allowed,
      minimumScore: max(1, target - delta),
      targetScore: target,
      officialAnswer: answer,
      hints: LevelHints(
        first: operatorHint,
        second: '완성된 수식의 기준 값은 $target이에요.',
        third: '정답 예시: $answer',
      ),
      difficulty: difficulty,
    );
  }
  throw StateError('Level $id 생성에 실패했습니다.');
}

class _Expression {
  const _Expression(this.text, this.precedence);
  final String text;
  final int precedence;
}

_Expression? _compose({
  required int target,
  required int leaves,
  required Set<String> allowed,
  required Random random,
  required int depth,
}) {
  if (leaves == 1) {
    return target >= 1 && target <= 9 ? _Expression('$target', 3) : null;
  }
  if (target <= 0 || depth > 12) return null;

  final operations = <String>['+', '-'];
  if (allowed.contains('×') && target > 1) operations.add('×');
  if (allowed.contains('÷')) operations.add('÷');
  operations.shuffle(random);

  for (var attempt = 0; attempt < 36; attempt++) {
    final operation = operations[attempt % operations.length];
    final leftLeaves = 1 + random.nextInt(leaves - 1);
    final rightLeaves = leaves - leftLeaves;
    var leftTarget = 0;
    var rightTarget = 0;
    switch (operation) {
      case '+':
        if (target <= 1) continue;
        rightTarget = 1 + random.nextInt(target - 1);
        leftTarget = target - rightTarget;
      case '-':
        rightTarget = 1 + random.nextInt(9 * rightLeaves);
        leftTarget = target + rightTarget;
      case '×':
        final factors = <int>[
          for (var factor = 2; factor <= min(9 * rightLeaves, target); factor++)
            if (target % factor == 0) factor,
        ];
        if (factors.isEmpty) continue;
        rightTarget = factors[random.nextInt(factors.length)];
        leftTarget = target ~/ rightTarget;
      case '÷':
        rightTarget = 2 + random.nextInt(min(8, 9 * rightLeaves - 1));
        leftTarget = target * rightTarget;
    }

    final left = _compose(
      target: leftTarget,
      leaves: leftLeaves,
      allowed: allowed,
      random: random,
      depth: depth + 1,
    );
    final right = _compose(
      target: rightTarget,
      leaves: rightLeaves,
      allowed: allowed,
      random: random,
      depth: depth + 1,
    );
    if (left == null || right == null) continue;

    final precedence = operation == '×' || operation == '÷' ? 2 : 1;
    var leftText = left.text;
    var rightText = right.text;
    if (left.precedence < precedence) leftText = '($leftText)';
    if (right.precedence < precedence ||
        ((operation == '-' || operation == '÷') &&
            right.precedence == precedence)) {
      rightText = '($rightText)';
    }
    return _Expression('$leftText$operation$rightText', precedence);
  }
  return null;
}

int _digitCountFor(int id) {
  if (id <= 10) return id % 3 == 0 ? 5 : 4;
  if (id <= 30) return id.isEven ? 5 : 6;
  if (id <= 70) return id.isEven ? 6 : 7;
  if (id <= 110) return id.isEven ? 7 : 8;
  if (id <= 170) return 8;
  return id.isEven ? 8 : 9;
}

int _difficultyFor(int id) {
  if (id <= 10) return 1;
  if (id <= 30) return 2;
  if (id <= 70) return 3;
  if (id <= 110) return 4;
  if (id <= 170) return 5;
  return 6;
}

String _operatorHint(Set<String> operators) {
  if (operators.contains('×') && operators.contains('÷')) {
    return '곱셈과 나눗셈의 순서를 함께 살펴보세요.';
  }
  if (operators.contains('×')) return '이 문제에는 곱셈 기호가 사용돼요.';
  if (operators.contains('÷')) return '나눗셈으로 수의 크기를 바꿔 보세요.';
  if (operators.contains('+') && operators.contains('-')) {
    return '덧셈과 뺄셈을 모두 사용해 보세요.';
  }
  return '같은 연산을 여러 번 배치해 보세요.';
}

LevelData _special({
  required int id,
  required String answer,
  required String perfectAnswer,
  required int target,
  required int perfectScore,
}) {
  final digits = answer.replaceAll(RegExp(r'[^0-9]'), '');
  final allowed = <String>{'+', '-', '='};
  if (answer.contains('×') || perfectAnswer.contains('×')) allowed.add('×');
  return LevelData(
    id: id,
    digitString: digits,
    availableOperators: allowed,
    minimumScore: max(1, target - max(1, target ~/ 3)),
    targetScore: target,
    officialAnswer: answer,
    perfectAnswer: perfectAnswer,
    possiblePerfectScore: perfectScore,
    hints: LevelHints(
      first: _operatorHint(allowed.difference({'='})),
      second: '완성된 수식의 기준 값은 $target이에요.',
      third: '정답 예시: $answer',
    ),
    difficulty: _difficultyFor(id),
  );
}

final Map<int, LevelData> _handcraftedLevels = {
  6: _special(
    id: 6,
    answer: '2=2+3+4-7',
    perfectAnswer: '2-2+3+4=7',
    target: 2,
    perfectScore: 7,
  ),
  12: _special(
    id: 12,
    answer: '2×2×3-4=8',
    perfectAnswer: '2×2×3=4+8',
    target: 8,
    perfectScore: 12,
  ),
  31: _special(
    id: 31,
    answer: '10-1-2×3+4=7',
    perfectAnswer: '10-1=2×3-4+7',
    target: 7,
    perfectScore: 9,
  ),
  71: _special(
    id: 71,
    answer: '10+0-1×2=3-4+9',
    perfectAnswer: '100+1-23×4=9',
    target: 8,
    perfectScore: 9,
  ),
  171: _special(
    id: 171,
    answer: '10+0+0-1×2=3-4+9',
    perfectAnswer: '100+0+1-23×4=9',
    target: 8,
    perfectScore: 9,
  ),
};
