import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/screens/home/level_list_screen.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';
import 'package:numbering/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fits a twenty-level pack in a five-by-four landscape grid',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final records = <int, LevelProgress>{
      for (var levelId = 1; levelId <= 5; levelId++)
        levelId: LevelProgress(
          levelId: levelId,
          cleared: true,
          stars: levelId == 5 ? 2 : 3,
        ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelGrid(
            pack: levelPacks.first,
            currentLevel: 6,
            records: records,
            packColor: AppColors.blockLilac,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final level1 = find.byKey(const ValueKey('level-tile-1'));
    final level5 = find.byKey(const ValueKey('level-tile-5'));
    final level6 = find.byKey(const ValueKey('level-tile-6'));
    final level16 = find.byKey(const ValueKey('level-tile-16'));
    final level20 = find.byKey(const ValueKey('level-tile-20'));

    expect(level1, findsOneWidget);
    expect(level20, findsOneWidget);
    expect(tester.getCenter(level1).dy, tester.getCenter(level5).dy);
    expect(
        tester.getCenter(level6).dy, greaterThan(tester.getCenter(level1).dy));
    expect(tester.getCenter(level16).dy, tester.getCenter(level20).dy);
    expect(tester.getBottomRight(level20).dy, lessThanOrEqualTo(280));
    expect(tester.getSize(level1).height, lessThan(80));

    expect(find.text('PLAY NEXT'), findsNothing);
    expect(find.text('OPEN'), findsNothing);
    expect(find.text('LOCKED'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });
}
