import 'dart:math';

/// Cross-platform deterministic PRNG used by official Numbering puzzles.
///
/// Park-Miller values stay below JavaScript's exact-integer limit, so the same
/// seed produces the same sequence on Flutter web and native platforms.
class NumberingPrng {
  NumberingPrng(int seed) : _state = _normalizeSeed(seed);

  static const int _modulus = 2147483647;
  static const int _multiplier = 48271;

  int _state;

  static int _normalizeSeed(int seed) {
    final normalized = seed % _modulus;
    return normalized <= 0 ? normalized + _modulus - 1 : normalized;
  }

  int nextInt(int upperBound) {
    if (upperBound <= 0) {
      throw RangeError.range(upperBound, 1, null, 'upperBound');
    }
    _state = (_state * _multiplier) % _modulus;
    return _state % upperBound;
  }
}

/// Builds eight deterministic random digits for the official daily puzzle.
String generateDailyNumberingPuzzle(int seed) {
  final random = NumberingPrng(seed);
  return List<String>.generate(
    8,
    (_) => '${1 + random.nextInt(9)}',
    growable: false,
  ).join();
}

/// Builds solvable N-digit (4, 5, 6) puzzles for Time Attack mode.
String generateTimeAttackPuzzle(int digitCount, [int? seed]) {
  final random = seed != null ? Random(seed) : Random();
  final allowed = const {'+', '-', '×', '÷', '='};

  for (var attempt = 0; attempt < 500; attempt++) {
    final leftLeaves = 1 + random.nextInt(digitCount - 1);
    final rightLeaves = digitCount - leftLeaves;
    final maxTarget = min(leftLeaves, rightLeaves) * 9;
    final target = 2 + random.nextInt(max(2, maxTarget - 1));

    final left = _composeTimeAttackExpr(
      target: target,
      leaves: leftLeaves,
      allowed: allowed,
      random: random,
      depth: 0,
    );
    final right = _composeTimeAttackExpr(
      target: target,
      leaves: rightLeaves,
      allowed: allowed,
      random: random,
      depth: 0,
    );

    if (left == null || right == null || left == right) continue;

    final equation = '$left=$right';
    final digits = equation.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == digitCount) {
      final list = digits.split('')..shuffle(random);
      return list.join();
    }
  }
  // Fallback
  return List.generate(digitCount, (_) => '${1 + random.nextInt(9)}').join();
}

String? _composeTimeAttackExpr({
  required int target,
  required int leaves,
  required Set<String> allowed,
  required Random random,
  required int depth,
}) {
  if (leaves == 1) {
    return target >= 1 && target <= 9 ? '$target' : null;
  }
  if (target <= 0 || depth > 8) return null;

  final ops = <String>['+', '-'];
  if (allowed.contains('×') && target > 1) ops.add('×');
  if (allowed.contains('÷') && target > 1) ops.add('÷');
  ops.shuffle(random);

  for (var i = 0; i < ops.length; i++) {
    final op = ops[i];
    final leftLeaves = 1 + random.nextInt(leaves - 1);
    final rightLeaves = leaves - leftLeaves;
    int leftTarget = 0;
    int rightTarget = 0;

    switch (op) {
      case '+':
        if (target <= 1) continue;
        rightTarget = 1 + random.nextInt(target - 1);
        leftTarget = target - rightTarget;
      case '-':
        rightTarget = 1 + random.nextInt(9 * rightLeaves);
        leftTarget = target + rightTarget;
      case '×':
        final factors = <int>[
          for (var f = 2; f <= min(9 * rightLeaves, target); f++)
            if (target % f == 0) f,
        ];
        if (factors.isEmpty) continue;
        rightTarget = factors[random.nextInt(factors.length)];
        leftTarget = target ~/ rightTarget;
      case '÷':
        rightTarget = 1 + random.nextInt(9 * rightLeaves);
        leftTarget = target * rightTarget;
    }

    final left = _composeTimeAttackExpr(
      target: leftTarget,
      leaves: leftLeaves,
      allowed: allowed,
      random: random,
      depth: depth + 1,
    );
    final right = _composeTimeAttackExpr(
      target: rightTarget,
      leaves: rightLeaves,
      allowed: allowed,
      random: random,
      depth: depth + 1,
    );
    if (left != null && right != null) {
      return '$left$op$right';
    }
  }
  return null;
}
