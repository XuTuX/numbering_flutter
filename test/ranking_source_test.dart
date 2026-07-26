import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arcade syncs account progress without affecting time attack rankings',
      () {
    final arcade = File(
      'lib/game/numbering/views/level_play_view.dart',
    ).readAsStringSync();
    final arcadeProgress = File(
      'lib/game/numbering/level_progress_service.dart',
    ).readAsStringSync();
    final homeContent = File(
      'lib/screens/home/widgets/home_screen_content_components.dart',
    ).readAsStringSync();
    final ranking =
        File('lib/screens/ranking/ranking_screen.dart').readAsStringSync();
    final scoreService =
        File('lib/services/time_attack_score_service.dart').readAsStringSync();
    final timeAttackMigration = File(
      'supabase/migrations/20260725203329_harden_numbering_time_attack.sql',
    ).readAsStringSync();
    final arcadeMigration = File(
      'supabase/migrations/20260726041000_sync_numbering_arcade_progress.sql',
    ).readAsStringSync();

    expect(arcade, isNot(contains('NumberingScoreService')));
    expect(
      arcadeProgress,
      contains('sync_my_numbering_arcade_progress'),
    );
    expect(
      arcadeMigration,
      contains(
          'alter table public.numbering_arcade_progress enable row level security'),
    );
    expect(
      arcadeMigration,
      contains('using ((select auth.uid()) = user_id)'),
    );
    expect(scoreService, contains('start_numbering_time_attack'));
    expect(scoreService, contains('submit_numbering_time_attack_solution'));
    expect(scoreService, contains('finish_numbering_time_attack'));

    expect(homeContent, contains('TimeAttackScoreService'));
    expect(ranking, contains('TimeAttackScoreService'));
    expect(
      timeAttackMigration,
      contains('total_score = total_score + v_score'),
    );
    expect(
      timeAttackMigration,
      contains(
        RegExp(
          r'order by\s+scores\.total_score desc,\s+'
          r'scores\.highest_number desc',
        ),
      ),
    );
  });
}
