import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/game/numbering/numbering_game_page.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/views/time_attack_play_view.dart';
import 'package:numbering/screens/game_screen.dart';
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
      'displays time attack header with timer, total score, and actions',
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

    // The server-verified accumulated score is the only score shown.
    expect(find.text('SCORE 0'), findsOneWidget);
    expect(find.textContaining('BEST'), findsNothing);
    expect(find.textContaining('TOTAL'), findsNothing);

    // Verify close (exit) and refresh (restart) buttons are displayed on the right
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  testWidgets('scales the time attack header with iPad portrait width',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(744, 1133);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const GameScreen(
          sessionConfig: GameSessionConfig(mode: GameMode.timeAttack),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final miniTimer = tester.widget<Text>(
      find.byKey(const ValueKey('time-attack-timer')),
    );
    final miniScore = tester.widget<Text>(
      find.byKey(const ValueKey('time-attack-score')),
    );
    final miniExit = tester.widget<IconButton>(
      find.byKey(const ValueKey('time-attack-exit')),
    );
    final miniDigit = tester.widget<AnimatedDefaultTextStyle>(
      find.descendant(
        of: find.byKey(const ValueKey('formula-digit-0')),
        matching: find.byType(AnimatedDefaultTextStyle),
      ),
    );

    tester.view.physicalSize = const Size(1032, 1376);
    await tester.pump();

    final largeTimer = tester.widget<Text>(
      find.byKey(const ValueKey('time-attack-timer')),
    );
    final largeScore = tester.widget<Text>(
      find.byKey(const ValueKey('time-attack-score')),
    );
    final largeExit = tester.widget<IconButton>(
      find.byKey(const ValueKey('time-attack-exit')),
    );
    final largeRestart = tester.widget<IconButton>(
      find.byKey(const ValueKey('time-attack-restart')),
    );
    final largeDigit = tester.widget<AnimatedDefaultTextStyle>(
      find.descendant(
        of: find.byKey(const ValueKey('formula-digit-0')),
        matching: find.byType(AnimatedDefaultTextStyle),
      ),
    );

    expect(miniTimer.style!.fontSize!, greaterThan(16));
    expect(
      largeTimer.style!.fontSize!,
      greaterThan(miniTimer.style!.fontSize!),
    );
    expect(
      largeScore.style!.fontSize!,
      greaterThan(miniScore.style!.fontSize!),
    );
    expect(largeExit.iconSize!, greaterThan(miniExit.iconSize!));
    expect(largeRestart.iconSize, largeExit.iconSize);
    expect(
      largeDigit.style.fontSize!,
      greaterThan(miniDigit.style.fontSize!),
    );
    expect(largeDigit.style.fontSize!, greaterThan(130));
    expect(tester.takeException(), isNull);
  });

  testWidgets('retries finish when the server still reports an active session',
      (tester) async {
    Get.delete<TimeAttackScoreService>(force: true);
    final service = _RetryingFinishTimeAttackScoreService();
    Get.put<TimeAttackScoreService>(service);

    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TimeAttackPlayView(
            session: const GameSessionConfig(mode: GameMode.timeAttack),
            accent: Colors.blue,
            onShowLevels: () {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(service.finishCalls, 2);
    expect(find.text('42'), findsOneWidget);
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
      // The UI must use the server-provided duration, not the device clock.
      expiresAt: DateTime.utc(2000),
      remainingMilliseconds: 180000,
    );
  }
}

class _RetryingFinishTimeAttackScoreService extends TimeAttackScoreService {
  int finishCalls = 0;

  @override
  Future<void> refreshLeaderboard({int limit = 100}) async {}

  @override
  Future<TimeAttackSession> startSession() async {
    return TimeAttackSession(
      id: 'retry-session',
      digits: '1233',
      puzzleIndex: 0,
      highestNumber: 0,
      totalScore: 0,
      expiresAt: DateTime.utc(2000),
      remainingMilliseconds: 20,
    );
  }

  @override
  Future<TimeAttackResult> finishSession(String sessionId) async {
    finishCalls++;
    if (finishCalls == 1) {
      throw const TimeAttackServiceException(
        'session_active',
        '게임이 아직 진행 중입니다.',
      );
    }
    return const TimeAttackResult(highestNumber: 42, totalScore: 84);
  }
}
