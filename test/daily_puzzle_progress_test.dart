import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/services/numbering_score_service.dart';

void main() {
  test('daily puzzle progress serializes all editor state', () {
    const progress = DailyPuzzleProgress(
      digits: ['2', '7', '2', '9'],
      operators: ['+', null, '='],
      parentheses: [DailyPuzzleParenthesis(start: 0, end: 1)],
    );

    final restored = DailyPuzzleProgress.fromJson(progress.toJson());
    expect(restored.digits, progress.digits);
    expect(restored.operators, progress.operators);
    expect(restored.parentheses.single.start, 0);
    expect(restored.parentheses.single.end, 1);
  });
}
