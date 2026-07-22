import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
          onSettingsTap: () {},
          onProfileTap: () {},
          onStartGame: () {},
          onStartDaily: () async {},
          onRankingTap: () {},
          currentLevel: 3,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the minimal bento home in landscape', (tester) async {
    await pumpHome(tester, surfaceSize: const Size(844, 390));

    expect(find.text('NUMBERING'), findsOneWidget);
    expect(find.text("Today's\nChallenge"), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    final challengeDate = find.byKey(const ValueKey('challenge-date'));
    expect(challengeDate, findsOneWidget);
    expect(
      tester.widget<Text>(challengeDate).data,
      matches(RegExp(r'^\d{2}\.\d{2}$')),
    );
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('SEOUL'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('arcade-round-background')),
      findsOneWidget,
    );
    expect(find.text('PLAY AT YOUR PACE'), findsNothing);
    expect(find.textContaining('JUL'), findsNothing);
    expect(find.textContaining('7-day streak'), findsNothing);
    expect(find.text('#24'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNWidgets(3));
    expect(find.textContaining('+3 today'), findsNothing);
    expect(find.text('Statistics'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the 7:3 layout on a compact landscape screen',
      (tester) async {
    await pumpHome(tester, surfaceSize: const Size(667, 375));

    expect(find.text("Today's\nChallenge"), findsOneWidget);
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('View Ranking'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
