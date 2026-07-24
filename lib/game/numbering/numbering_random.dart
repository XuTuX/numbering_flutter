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

/// Builds guaranteed solvable N-digit (4, 5, 6) puzzles for Time Attack mode.
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
    if (digits.length == digitCount && isSolvableTimeAttackPuzzle(digits)) {
      final list = digits.split('')..shuffle(random);
      return list.join();
    }
  }

  // Guaranteed solver verification loop: keep trying random digits until a 100% solvable set is found
  while (true) {
    final candidate =
        List.generate(digitCount, (_) => '${1 + random.nextInt(9)}').join();
    if (isSolvableTimeAttackPuzzle(candidate)) {
      return candidate;
    }
  }
}

/// Checks if a string of digits can form at least one valid equality equation using +, -, ×, ÷.
bool isSolvableTimeAttackPuzzle(String digitString) {
  final digits = digitString.split('');
  final n = digits.length;
  final perms = _getUniquePermutations(digits);

  for (final perm in perms) {
    for (var split = 1; split < n; split++) {
      final leftDigits = perm.sublist(0, split);
      final rightDigits = perm.sublist(split);

      final leftValues = _evaluateAllPossibleValues(leftDigits);
      if (leftValues.isEmpty) continue;

      final rightValues = _evaluateAllPossibleValues(rightDigits);
      if (rightValues.isEmpty) continue;

      for (final val in leftValues) {
        if (rightValues.contains(val)) {
          return true;
        }
      }
    }
  }
  return false;
}

Set<int> _evaluateAllPossibleValues(List<String> digits) {
  final results = <int>{};
  final n = digits.length;
  if (n == 1) {
    results.add(int.parse(digits[0]));
    return results;
  }

  for (var i = 1; i < n; i++) {
    final leftVals = _evaluateAllPossibleValues(digits.sublist(0, i));
    final rightVals = _evaluateAllPossibleValues(digits.sublist(i));

    for (final l in leftVals) {
      for (final r in rightVals) {
        results.add(l + r);
        if (l - r >= 0) results.add(l - r);
        results.add(l * r);
        if (r != 0 && l % r == 0) results.add(l ~/ r);
      }
    }
  }
  return results;
}

Set<List<String>> _getUniquePermutations(List<String> list) {
  final results = <List<String>>{};
  _permuteHelper(list, 0, results);
  return results;
}

void _permuteHelper(List<String> list, int index, Set<List<String>> results) {
  if (index == list.length - 1) {
    results.add(List.from(list));
    return;
  }
  final seen = <String>{};
  for (var i = index; i < list.length; i++) {
    if (seen.contains(list[i])) continue;
    seen.add(list[i]);
    _swap(list, index, i);
    _permuteHelper(list, index + 1, results);
    _swap(list, index, i);
  }
}

void _swap(List<String> list, int i, int j) {
  final temp = list[i];
  list[i] = list[j];
  list[j] = temp;
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
