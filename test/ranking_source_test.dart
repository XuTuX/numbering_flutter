import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rankings use time attack results and arcade stores level progress locally', () {
    final arcade = File(
      'lib/game/numbering/views/level_play_view.dart',
    ).readAsStringSync();
    final home = File('lib/screens/home/home_screen.dart').readAsStringSync();
    final ranking =
        File('lib/screens/ranking/ranking_screen.dart').readAsStringSync();
    final scoreService =
        File('lib/services/numbering_score_service.dart').readAsStringSync();

    expect(arcade, isNot(contains('NumberingScoreService')));
    expect(scoreService, isNot(contains('submitNormalResult')));

    expect(home, contains('TimeAttackScoreService'));
    expect(ranking, contains('TimeAttackScoreService'));
  });
}
