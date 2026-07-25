import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'rankings use time attack results and arcade stores level progress locally',
      () {
    final arcade = File(
      'lib/game/numbering/views/level_play_view.dart',
    ).readAsStringSync();
    final homeContent = File(
      'lib/screens/home/widgets/home_screen_content_components.dart',
    ).readAsStringSync();
    final ranking =
        File('lib/screens/ranking/ranking_screen.dart').readAsStringSync();
    final scoreService =
        File('lib/services/time_attack_score_service.dart').readAsStringSync();

    expect(arcade, isNot(contains('NumberingScoreService')));
    expect(scoreService, contains('start_numbering_time_attack'));
    expect(scoreService, contains('submit_numbering_time_attack_solution'));
    expect(scoreService, contains('finish_numbering_time_attack'));

    expect(homeContent, contains('TimeAttackScoreService'));
    expect(ranking, contains('TimeAttackScoreService'));
  });
}
