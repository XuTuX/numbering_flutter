import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
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
    expect(
      find.byKey(const ValueKey('formula-digit-drag-0')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(hintButton);
    await tester.pumpAndSettle();

    final inlineHint = find.byKey(const ValueKey('inline-level-hint'));
    expect(inlineHint, findsOneWidget);
    expect(find.text(LevelCatalog.byId(1).hints.first), findsOneWidget);
    expect(
      tester.getCenter(inlineHint).dy,
      greaterThan(
          tester.getCenter(find.byKey(const ValueKey('formula-digit-0'))).dy),
    );
    expect(tester.getCenter(inlineHint).dy,
        lessThan(tester.getCenter(plusOperator).dy));

    await tester.tap(hintButton);
    await tester.tap(hintButton);
    await tester.pumpAndSettle();

    final hints = LevelCatalog.byId(1).hints;
    expect(find.text(hints.first), findsOneWidget);
    expect(find.text(hints.second), findsOneWidget);
    expect(find.text(hints.third), findsOneWidget);
    expect(hints.third, startsWith('정답:'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('places an operator using formula-row coordinates',
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

    expect(find.byType(DragTarget<InlineOperator>), findsNothing);
    expect(find.text('+'), findsOneWidget);

    final draggable = find.byKey(const ValueKey('operator-drag-+'));
    final rightDigit = find.byKey(const ValueKey('formula-digit-1'));
    final gesture = await tester.startGesture(tester.getCenter(draggable));
    await tester.pump();

    // The 52dp landscape feedback is anchored 0.85 × its size above the
    // pointer, so place the pointer below the target digit to align its center.
    await gesture.moveTo(tester.getCenter(rightDigit) + const Offset(0, 44.2));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('+'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily puzzle uses the same inline game editor', (tester) async {
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
                  mode: GameMode.dailyPractice,
                  seed: 123456,
                  dateKey: '2026-07-23',
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

    expect(find.text('오늘의 퍼즐'), findsOneWidget);
    expect(find.byTooltip('나가기'), findsOneWidget);
    expect(find.byKey(const ValueKey('formula-digit-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('formula-digit-7')), findsOneWidget);
    expect(find.byKey(const ValueKey('operator-drag-+')), findsOneWidget);
    expect(find.byKey(const ValueKey('operator-drag-=')), findsOneWidget);
    expect(find.text('수식을 입력하세요'), findsNothing);

    final firstDigitText = find.byKey(const ValueKey('formula-digit-text-0'));
    final secondDigitText = find.byKey(const ValueKey('formula-digit-text-1'));
    expect(
      tester.getTopLeft(secondDigitText).dx -
          tester.getTopRight(firstDigitText).dx,
      greaterThanOrEqualTo(7),
    );

    final firstDigit = find.byKey(const ValueKey('formula-digit-0'));
    final secondDigit = find.byKey(const ValueKey('formula-digit-1'));
    await tester.drag(
      firstDigit,
      tester.getCenter(secondDigit) - tester.getCenter(firstDigit),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: firstDigit, matching: find.text('7')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: secondDigit, matching: find.text('2')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
