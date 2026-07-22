import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:numbering/widgets/home_screen/login_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLoginSheet(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: LoginSheet(
            initialError: '로그인이 필요합니다.',
            onGoogleSignIn: () async => null,
            onAppleSignIn: () async => null,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('keeps the login sheet compact in landscape', (tester) async {
    await pumpLoginSheet(tester, surfaceSize: const Size(844, 390));

    expect(find.text('로그인'), findsNothing);
    expect(find.text('로그인이 필요합니다.'), findsNothing);
    expect(
      find.text('로그인하고 랭킹 · 오늘의 도전에 참여하세요'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('개인정보 처리방침'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the login sheet readable in portrait', (tester) async {
    await pumpLoginSheet(tester, surfaceSize: const Size(390, 844));

    expect(find.text('로그인'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
