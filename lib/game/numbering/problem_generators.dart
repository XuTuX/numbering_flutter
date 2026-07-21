import 'dart:math';

class FormulaProblem {
  const FormulaProblem({
    required this.digitString,
    required this.knownSolution,
  });

  final String digitString;
  final String knownSolution;

  List<String> get digits => digitString.split('');
}

abstract class _ExprNode {
  int evaluate();
  @override
  String toString();
  int get digitCount => toString().replaceAll(RegExp(r'[^0-9]'), '').length;
}

class _LiteralNode extends _ExprNode {
  _LiteralNode(this.value);
  final int value;
  @override
  int evaluate() => value;
  @override
  String toString() => value.toString();
}

class _BinaryOpNode extends _ExprNode {
  _BinaryOpNode(this.left, this.right, this.op);
  final _ExprNode left;
  final _ExprNode right;
  final String op;

  @override
  int evaluate() {
    switch (op) {
      case '+':
        return left.evaluate() + right.evaluate();
      case '-':
        return left.evaluate() - right.evaluate();
      case '×':
        return left.evaluate() * right.evaluate();
      case '÷':
        return left.evaluate() ~/ right.evaluate();
      default:
        throw StateError('Unknown op: $op');
    }
  }

  @override
  String toString() {
    String lStr = left.toString();
    String rStr = right.toString();

    // Add parentheses if needed for precedence
    final leftOp = left is _BinaryOpNode ? (left as _BinaryOpNode).op : null;
    final rightOp = right is _BinaryOpNode ? (right as _BinaryOpNode).op : null;
    bool lNeedsParens = leftOp != null && _precedence(op) > _precedence(leftOp);
    // For right side, we need parens if precedence is lower OR if it's same precedence but a non-associative operator like - or ÷
    bool rNeedsParens = false;
    if (rightOp != null) {
      if (_precedence(op) > _precedence(rightOp)) rNeedsParens = true;
      if (_precedence(op) == _precedence(rightOp) && (op == '-' || op == '÷')) {
        rNeedsParens = true;
      }
    }

    if (lNeedsParens) lStr = '($lStr)';
    if (rNeedsParens) rStr = '($rStr)';

    return '$lStr$op$rStr';
  }

  int _precedence(String op) => (op == '×' || op == '÷') ? 2 : 1;
}

_ExprNode _generateTree(
    Random random, int target, int maxNodes, bool allowMultDiv) {
  if (maxNodes <= 1 || target < 1) return _LiteralNode(max(1, target));

  List<String> ops = ['+'];
  if (target > 1) ops.add('-');
  if (allowMultDiv) {
    ops.add('×');
    ops.add('÷');
  }

  ops.shuffle(random);

  for (final op in ops) {
    if (op == '+') {
      int leftTarget = 1 + random.nextInt(target > 1 ? target - 1 : 1);
      int rightTarget = target - leftTarget;
      int leftNodes = 1 + random.nextInt(maxNodes - 1);
      int rightNodes = maxNodes - leftNodes;
      return _BinaryOpNode(
        _generateTree(random, leftTarget, leftNodes, allowMultDiv),
        _generateTree(random, rightTarget, rightNodes, allowMultDiv),
        '+',
      );
    } else if (op == '-') {
      int rightTarget = 1 + random.nextInt(20);
      int leftTarget = target + rightTarget;
      int leftNodes = 1 + random.nextInt(maxNodes - 1);
      int rightNodes = maxNodes - leftNodes;
      return _BinaryOpNode(
        _generateTree(random, leftTarget, leftNodes, allowMultDiv),
        _generateTree(random, rightTarget, rightNodes, allowMultDiv),
        '-',
      );
    } else if (op == '×') {
      List<int> factors = [];
      for (int i = 2; i <= target ~/ 2; i++) {
        if (target % i == 0) factors.add(i);
      }
      if (factors.isNotEmpty) {
        int leftTarget = factors[random.nextInt(factors.length)];
        int rightTarget = target ~/ leftTarget;
        int leftNodes = 1 + random.nextInt(maxNodes - 1);
        int rightNodes = maxNodes - leftNodes;
        return _BinaryOpNode(
          _generateTree(random, leftTarget, leftNodes, allowMultDiv),
          _generateTree(random, rightTarget, rightNodes, allowMultDiv),
          '×',
        );
      }
    } else if (op == '÷') {
      int rightTarget = 2 + random.nextInt(9);
      int leftTarget = target * rightTarget;
      int leftNodes = 1 + random.nextInt(maxNodes - 1);
      int rightNodes = maxNodes - leftNodes;
      return _BinaryOpNode(
        _generateTree(random, leftTarget, leftNodes, allowMultDiv),
        _generateTree(random, rightTarget, rightNodes, allowMultDiv),
        '÷',
      );
    }
  }

  return _LiteralNode(max(1, target));
}

FormulaProblem generateFormulaProblem(Random random, int round) {
  bool allowMultDiv = round >= 10;

  int targetValue;
  int maxLhsNodes;
  int maxRhsNodes;
  int maxDigits = 7;

  if (round <= 5) {
    targetValue = 2 + random.nextInt(10);
    maxLhsNodes = 2;
    maxRhsNodes = 1;
    maxDigits = 4;
  } else if (round <= 20) {
    targetValue = 5 + random.nextInt(20);
    maxLhsNodes = 2;
    maxRhsNodes = 2;
    maxDigits = 5;
  } else if (round <= 50) {
    targetValue = 10 + random.nextInt(30);
    maxLhsNodes = 2;
    maxRhsNodes = 2;
    if (random.nextBool()) {
      maxLhsNodes = 3;
      maxRhsNodes = 1;
    }
    maxDigits = 6;
  } else if (round <= 100) {
    targetValue = 15 + random.nextInt(50);
    maxLhsNodes = 3;
    maxRhsNodes = 2;
    maxDigits = 6;
  } else {
    targetValue = 20 + random.nextInt(80);
    maxLhsNodes = 3;
    maxRhsNodes = 3;
    maxDigits = 7;
  }

  _ExprNode lhs;
  _ExprNode rhs;
  String lhsStr;
  String rhsStr;
  String digits;

  // Retry logic to ensure digits don't exceed maxDigits
  while (true) {
    lhs = _generateTree(random, targetValue, maxLhsNodes, allowMultDiv);
    rhs = _generateTree(random, targetValue, maxRhsNodes, allowMultDiv);
    lhsStr = lhs.toString();
    rhsStr = rhs.toString();

    digits = '$lhsStr$rhsStr'.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= maxDigits && digits.length >= 3) {
      // Ensure we don't accidentally generate identical sides like `5 = 5` unless it's a very early round
      if (lhsStr == rhsStr && round > 2) {
        targetValue += 1; // Mutate target and try again
        continue;
      }
      break;
    }

    // If we exceed max digits, reduce target or nodes and try again
    if (digits.length > maxDigits) {
      if (maxLhsNodes > 1) maxLhsNodes--;
      if (maxRhsNodes > 1) maxRhsNodes--;
      targetValue = max(10, targetValue - 5);
    } else if (digits.length < 3) {
      // We want at least 3 digits for a meaningful game
      targetValue += 10;
      if (maxLhsNodes < 3) maxLhsNodes++;
    }
  }

  return FormulaProblem(
    digitString: digits,
    knownSolution: '$lhsStr=$rhsStr',
  );
}
