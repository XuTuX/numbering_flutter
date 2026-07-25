import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/game/numbering/numbering_game_page.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final progress = await LevelProgressService().init();
    Get.put<LevelProgressService>(progress);
    final hintService = await HintService().init();
    Get.put<HintService>(hintService);
    Get.put<AuthService>(AuthService());
    Get.put<TimeAttackScoreService>(_FakeTimeAttackScoreService());
  });

  tearDown(Get.reset);

  testWidgets(
      'displays time attack header without Time Attack text, timer on left, BEST TOTAL in center, refresh on right',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SafeArea(
            child: NumberingGamePage(
              game: NumberingGame.formulaWorkshop,
              session: const GameSessionConfig(
                mode: GameMode.timeAttack,
              ),
              callbacks: GameCallbacks(
                onScoreChanged: (_) {},
                onFinished: (_) {},
                onExit: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 'Time Attack' text is NOT displayed anywhere
    expect(find.textContaining('Time Attack'), findsNothing);

    // Verify timer text '03:00' is displayed on the left
    expect(find.text('03:00'), findsOneWidget);

    // Verify BEST & TOTAL text is displayed in center
    expect(find.text('BEST 0  TOTAL 0'), findsOneWidget);

    // Verify close (exit) and refresh (restart) buttons are displayed on the right
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}

class _FakeTimeAttackScoreService extends TimeAttackScoreService {
  @override
  Future<void> refreshLeaderboard({int limit = 100}) async {}

  @override
  Future<TimeAttackSession> startSession() async {
    return TimeAttackSession(
      id: 'test-session',
      digits: '1233',
      puzzleIndex: 0,
      highestNumber: 0,
      totalScore: 0,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 3)),
    );
  }
}
