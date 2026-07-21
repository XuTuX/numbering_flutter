import 'package:flutter/foundation.dart';

import 'numbering_models.dart';

enum InlineOperator {
  add('+'),
  subtract('-'),
  multiply('×'),
  divide('÷'),
  equals('=');

  const InlineOperator(this.symbol);

  final String symbol;
}

@immutable
class OperatorSlot {
  const OperatorSlot({required this.index, this.operator});

  final int index;
  final InlineOperator? operator;
}

@immutable
class ParenthesisRange {
  const ParenthesisRange({
    required this.id,
    required this.startDigitIndex,
    required this.endDigitIndex,
  });

  final String id;
  final int startDigitIndex;
  final int endDigitIndex;

  ParenthesisRange normalized() {
    if (startDigitIndex <= endDigitIndex) return this;
    return ParenthesisRange(
      id: id,
      startDigitIndex: endDigitIndex,
      endDigitIndex: startDigitIndex,
    );
  }
}

String assembleInlineExpression({
  required List<String> digits,
  required List<InlineOperator?> operators,
  List<ParenthesisRange> parentheses = const [],
}) {
  if (operators.length != digits.length - 1) {
    throw ArgumentError('연산자 슬롯 수가 숫자 사이의 칸 수와 다릅니다.');
  }

  final normalized = parentheses.map((range) => range.normalized()).toList();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final openingCount =
        normalized.where((range) => range.startDigitIndex == index).length;
    final closingCount =
        normalized.where((range) => range.endDigitIndex == index).length;
    buffer.write('(' * openingCount);
    buffer.write(digits[index]);
    buffer.write(')' * closingCount);
    if (index < operators.length) {
      buffer.write(operators[index]?.symbol ?? '');
    }
  }
  return buffer.toString();
}

ValidationResult validateParenthesisRange({
  required int digitCount,
  required ParenthesisRange candidate,
  required List<ParenthesisRange> existing,
}) {
  final range = candidate.normalized();
  if (range.startDigitIndex < 0 || range.endDigitIndex >= digitCount) {
    return const ValidationResult.failure('괄호 범위가 숫자 영역을 벗어났습니다.');
  }
  if (range.startDigitIndex == range.endDigitIndex) {
    return const ValidationResult.failure('숫자 하나만 괄호로 묶을 수 없습니다.');
  }

  for (final rawOther in existing) {
    final other = rawOther.normalized();
    if (range.startDigitIndex == other.startDigitIndex &&
        range.endDigitIndex == other.endDigitIndex) {
      return const ValidationResult.failure('같은 괄호 범위가 이미 있습니다.');
    }
    final overlaps = range.startDigitIndex <= other.endDigitIndex &&
        other.startDigitIndex <= range.endDigitIndex;
    final rangeContainsOther = range.startDigitIndex <= other.startDigitIndex &&
        range.endDigitIndex >= other.endDigitIndex;
    final otherContainsRange = other.startDigitIndex <= range.startDigitIndex &&
        other.endDigitIndex >= range.endDigitIndex;
    if (overlaps && !rangeContainsOther && !otherContainsRange) {
      return const ValidationResult.failure('괄호 범위끼리 교차할 수 없습니다.');
    }
  }
  return const ValidationResult.success(0);
}

ValidationResult evaluateIntegerExpression(String source) {
  final values = <int>[];
  final operators = <String>[];
  var index = 0;
  var expectsOperand = true;

  ValidationResult fail(String message) => ValidationResult.failure(message);

  ValidationResult applyTopOperator() {
    if (operators.isEmpty || values.length < 2) {
      return fail('수식의 피연산자가 부족합니다.');
    }
    final operator = operators.removeLast();
    final right = values.removeLast();
    final left = values.removeLast();
    switch (operator) {
      case '+':
        values.add(left + right);
      case '-':
        values.add(left - right);
      case '×':
        values.add(left * right);
      case '÷':
        if (right == 0) return fail('0으로 나눌 수 없습니다.');
        if (left % right != 0) {
          return fail('나눗셈의 중간 결과는 정수여야 합니다.');
        }
        values.add(left ~/ right);
      default:
        return fail('알 수 없는 연산자입니다.');
    }
    return ValidationResult.success(values.last);
  }

  int precedence(String operator) => operator == '×' || operator == '÷' ? 2 : 1;

  while (index < source.length) {
    final character = source[index];
    if (character.trim().isEmpty) {
      index++;
      continue;
    }
    final isDigit =
        character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;
    if (isDigit) {
      if (!expectsOperand) return fail('숫자 사이에 연산자가 필요합니다.');
      final start = index;
      while (index < source.length) {
        final code = source.codeUnitAt(index);
        if (code < 48 || code > 57) break;
        index++;
      }
      values.add(int.parse(source.substring(start, index)));
      expectsOperand = false;
      continue;
    }
    if (character == '(') {
      if (!expectsOperand) return fail('암시적 곱셈은 허용하지 않습니다.');
      operators.add(character);
      index++;
      continue;
    }
    if (character == ')') {
      if (expectsOperand) return fail('비어 있거나 잘못된 괄호입니다.');
      while (operators.isNotEmpty && operators.last != '(') {
        final result = applyTopOperator();
        if (!result.valid) return result;
      }
      if (operators.isEmpty || operators.removeLast() != '(') {
        return fail('닫는 괄호와 짝이 맞지 않습니다.');
      }
      expectsOperand = false;
      index++;
      continue;
    }
    if (character == '+' ||
        character == '-' ||
        character == '×' ||
        character == '÷') {
      if (expectsOperand) return fail('단항 연산자는 허용하지 않습니다.');
      while (operators.isNotEmpty &&
          operators.last != '(' &&
          precedence(operators.last) >= precedence(character)) {
        final result = applyTopOperator();
        if (!result.valid) return result;
      }
      operators.add(character);
      expectsOperand = true;
      index++;
      continue;
    }
    return fail('허용되지 않은 문자입니다: $character');
  }

  if (values.isEmpty) return fail('수식이 비어 있습니다.');
  if (expectsOperand) return fail('수식이 연산자로 끝날 수 없습니다.');
  while (operators.isNotEmpty) {
    if (operators.last == '(') return fail('여는 괄호와 짝이 맞지 않습니다.');
    final result = applyTopOperator();
    if (!result.valid) return result;
  }
  if (values.length != 1) return fail('올바른 수식이 아닙니다.');
  return ValidationResult.success(values.single);
}

ValidationResult validateFormulaWorkshop({
  required String digitString,
  required String expression,
}) {
  return validateLevelFormula(
    digitString: digitString,
    expression: expression,
    availableOperators: const {'+', '-', '×', '÷', '='},
  );
}

ValidationResult validateLevelFormula({
  required String digitString,
  required String expression,
  required Set<String> availableOperators,
}) {
  final preservedDigits = expression.replaceAll(RegExp(r'[^0-9]'), '');
  if (preservedDigits != digitString) {
    return const ValidationResult.failure('주어진 숫자를 순서대로 모두 사용해야 합니다.');
  }
  for (final match in RegExp(r'[+\-×÷=]').allMatches(expression)) {
    final symbol = match.group(0)!;
    if (!availableOperators.contains(symbol)) {
      return ValidationResult.failure('$symbol 기호는 이 레벨에서 사용할 수 없습니다.');
    }
  }
  final equalsCount = '='.allMatches(expression).length;
  if (equalsCount != 1) {
    return const ValidationResult.failure('등호를 정확히 하나 사용해야 합니다.');
  }
  final sides = expression.split('=');
  if (sides.any((side) => side.trim().isEmpty)) {
    return const ValidationResult.failure('등호 양쪽에 수식이 필요합니다.');
  }
  final left = evaluateIntegerExpression(sides[0]);
  if (!left.valid) return left;
  final right = evaluateIntegerExpression(sides[1]);
  if (!right.valid) return right;
  if (left.value != right.value) {
    return const ValidationResult.failure('등호 양쪽의 값이 다릅니다.');
  }
  return ValidationResult.success(left.value!);
}
