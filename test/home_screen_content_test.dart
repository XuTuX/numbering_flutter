import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreenContent(
          scoreController: ScoreController(),
          onSettingsTap: () {},
          onProfileTap: () {},
          onStartGame: () {},
          onStartDaily: () async {},
          onRankingTap: () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the minimal bento home in landscape', (tester) async {
    await pumpHome(tester, surfaceSize: const Size(844, 390));

    expect(find.text('NUMBERING'), findsOneWidget);
    expect(find.text("Today's\nChallenge"), findsOneWidget);
    expect(find.text('Start Puzzle'), findsOneWidget);
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('#24'), findsOneWidget);
    expect(find.text('Statistics'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the 7:3 layout on a compact landscape screen',
      (tester) async {
    await pumpHome(tester, surfaceSize: const Size(667, 375));

    expect(find.text("Today's\nChallenge"), findsOneWidget);
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('View Ranking'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
