import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:numbering/screens/home/widgets/home_screen_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size surfaceSize,
    String? nickname,
    VoidCallback? onNicknameTap,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreenContent(
          onSettingsTap: () {},
          onStartGame: () {},
          onStartTimeAttack: () {},
          onRankingTap: () {},
          nickname: nickname,
          onNicknameTap: onNicknameTap,
          currentLevel: 3,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows Arcade and Time Attack home cards in landscape', (tester) async {
    await pumpHome(tester, surfaceSize: const Size(844, 390));

    expect(find.text('NUMBERING'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('SEOUL'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('arcade-round-background')),
      findsOneWidget,
    );
    expect(find.text('Time Attack'), findsOneWidget);
    expect(find.text('3 MIN'), findsOneWidget);
    expect(find.text('#—'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNWidgets(3));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the signed-in nickname and makes it editable',
      (tester) async {
    var nicknameTapped = false;
    await pumpHome(
      tester,
      surfaceSize: const Size(844, 390),
      nickname: '퍼즐고래',
      onNicknameTap: () => nicknameTapped = true,
    );

    expect(find.text('NUMBERING'), findsNothing);
    expect(find.text('퍼즐고래'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nickname')), findsOneWidget);

    await tester.tap(find.text('퍼즐고래'));
    expect(nicknameTapped, isTrue);
  });

  testWidgets('keeps the layout on a compact landscape screen',
      (tester) async {
    await pumpHome(tester, surfaceSize: const Size(667, 375));

    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('Time Attack'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
