import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/game/numbering/numbering_game_page.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final progress = await LevelProgressService().init();
    Get.put<LevelProgressService>(progress);
  });

  tearDown(Get.reset);

  testWidgets('keeps operators low and aligns the hint control',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: NumberingGamePage(
                game: NumberingGame.formulaWorkshop,
                session: const GameSessionConfig(
                  mode: GameMode.normal,
                  startLevelId: 1,
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
      ),
    );
    await tester.pumpAndSettle();

    final plusOperator = find.text('+').last;
    expect(tester.getCenter(plusOperator).dy, greaterThan(250));

    final backButton = find.byTooltip('레벨 목록');
    expect(tester.getTopLeft(backButton).dy, greaterThanOrEqualTo(20));

    final hintButton = find.byKey(const ValueKey('level-hint-button'));
    expect(hintButton, findsOneWidget);
    expect(tester.getSize(hintButton), const Size(44, 44));
    expect(tester.takeException(), isNull);

    await tester.tap(hintButton);
    await tester.pumpAndSettle();

    expect(find.text('힌트'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
