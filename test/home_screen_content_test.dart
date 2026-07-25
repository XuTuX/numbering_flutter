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
}
