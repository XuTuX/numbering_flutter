import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:numbering/screens/settings/settings_screen.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSettings(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });

    Get.put(SettingsService());

    await tester.pumpWidget(
      GetMaterialApp(
        home: SettingsScreen(authService: AuthService()),
      ),
    );
    await tester.pump();
  }

  testWidgets('uses a side navigation on wide screens', (tester) async {
    await pumpSettings(tester, surfaceSize: const Size(1180, 820));

    expect(
      find.byKey(const ValueKey('settings-side-navigation')),
      findsOneWidget,
    );
    expect(find.text('일반'), findsNWidgets(2));
    expect(find.text('계정'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a single column on compact screens', (tester) async {
    await pumpSettings(tester, surfaceSize: const Size(390, 844));

    expect(
      find.byKey(const ValueKey('settings-side-navigation')),
      findsNothing,
    );
    expect(find.text('일반'), findsOneWidget);
    expect(find.text('계정'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
