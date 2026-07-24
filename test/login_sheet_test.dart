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

  testWidgets('required login screen has no guest entry path', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var googleAttempts = 0;
    await tester.pumpWidget(
      GetMaterialApp(
        home: RequiredLoginScreen(
          onGoogleSignIn: () async {
            googleAttempts++;
            return '로그인에 실패했어요. 다시 시도해 주세요.';
          },
          onAppleSignIn: () async => null,
        ),
      ),
    );

    expect(find.text('로그인 후 시작할 수 있어요'), findsOneWidget);
    expect(
      find.text('NUMBERING을 이용하려면 먼저 로그인해 주세요.'),
      findsOneWidget,
    );
    expect(find.textContaining('건너뛰'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('google-sign-in-button')));
    await tester.pumpAndSettle();

    expect(googleAttempts, 1);
    expect(
      find.text('로그인에 실패했어요. 다시 시도해 주세요.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
