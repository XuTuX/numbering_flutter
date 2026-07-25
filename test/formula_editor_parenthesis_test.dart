import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/game/numbering/numbering_game_page.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/services/hint_service.dart';
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
  });

  tearDown(Get.reset);

  testWidgets(
      'tapping two digits adds parentheses and tapping again removes them',
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
                mode: GameMode.normal,
                startLevelId: 1,
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

    final firstDigit = find.byKey(const ValueKey('formula-digit-0'));
    final thirdDigit = find.byKey(const ValueKey('formula-digit-2'));

    // Before tapping, no parentheses text
    expect(find.textContaining('('), findsNothing);
    expect(find.textContaining(')'), findsNothing);

    // Tap first digit, then third digit
    await tester.tap(firstDigit);
    await tester.pump();
    await tester.tap(thirdDigit);
    await tester.pumpAndSettle();

    // Now parentheses should be displayed around the selected range
    expect(find.textContaining('('), findsOneWidget);
    expect(find.textContaining(')'), findsOneWidget);

    // Tapping the same two digits again removes parentheses
    await tester.tap(firstDigit);
    await tester.pump();
    await tester.tap(thirdDigit);
    await tester.pumpAndSettle();

    expect(find.textContaining('('), findsNothing);
    expect(find.textContaining(')'), findsNothing);
  });
}
