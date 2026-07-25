import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:numbering/screens/home/widgets/home_screen_content.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size surfaceSize,
    String? nickname,
    VoidCallback? onNicknameTap,
    double textScaleFactor = 1,
  }) async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });

    final authService = Get.put<AuthService>(AuthService());
    Get.put<TimeAttackScoreService>(TimeAttackScoreService());
    if (nickname != null) {
      authService.user.value = User(
        id: 'test-user',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      authService.userNickname.value = nickname;
    }

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child!,
        ),
        home: HomeScreenContent(
          onSettingsTap: () {},
          onStartGame: () {},
          onStartTimeAttack: () {},
          onRankingTap: () {},
          onNicknameTap: onNicknameTap ?? () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows minimal Arcade and Time Attack home cards in landscape',
      (tester) async {
    await pumpHome(tester, surfaceSize: const Size(844, 390));

    expect(find.text('NUMBERING'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('Time Attack'), findsOneWidget);
    expect(find.text('YOUR RANK'), findsOneWidget);
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

  testWidgets('keeps the layout on a compact landscape screen', (tester) async {
    await pumpHome(tester, surfaceSize: const Size(667, 375));

    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('Time Attack'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stacks cards on a narrow portrait screen without overflow',
      (tester) async {
    await pumpHome(
      tester,
      surfaceSize: const Size(390, 844),
      textScaleFactor: 1.5,
    );

    final arcade = tester.getCenter(find.text('Arcade'));
    final timeAttack = tester.getCenter(find.text('Time Attack'));
    final rank = tester.getCenter(find.text('YOUR RANK'));
    expect(arcade.dy, lessThan(timeAttack.dy));
    expect((timeAttack.dy - rank.dy).abs(), lessThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the wide card layout on an iPad portrait screen',
      (tester) async {
    await pumpHome(tester, surfaceSize: const Size(768, 1024));

    final arcade = tester.getCenter(find.text('Arcade'));
    final timeAttack = tester.getCenter(find.text('Time Attack'));
    expect(arcade.dx, lessThan(timeAttack.dx));
    expect(tester.takeException(), isNull);
  });
}
