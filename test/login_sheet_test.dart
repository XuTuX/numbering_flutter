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

    expect(find.text('NUMBERING'), findsOneWidget);
    expect(find.text('로그인하여 플레이해보세요'), findsOneWidget);
    expect(find.text('로그인이 필요합니다.'), findsNothing);
    expect(
      find.byKey(const ValueKey('google-sign-in-button')),
      findsOneWidget,
    );
    expect(find.text('Google로 계속하기'), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('개인정보 처리방침'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the login sheet readable in portrait', (tester) async {
    await pumpLoginSheet(tester, surfaceSize: const Size(390, 844));

    expect(find.text('NUMBERING'), findsOneWidget);
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

    expect(find.text('로그인하여 플레이해보세요'), findsNothing);
    expect(
      find.byKey(const ValueKey('login-number-motion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('google-sign-in-button')),
      findsOneWidget,
    );
    expect(find.text('Google'), findsOneWidget);
    expect(find.textContaining('건너뛰'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('google-sign-in-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(googleAttempts, 1);
    expect(
      find.text('로그인에 실패했어요. 다시 시도해 주세요.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('required login screen fits compact landscape', (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        home: RequiredLoginScreen(
          onGoogleSignIn: () async => null,
          onAppleSignIn: () async => null,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('login-number-motion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('google-sign-in-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('required login overlay supports tooltips above the navigator', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => RequiredLoginOverlay(
          onGoogleSignIn: () async => null,
          onAppleSignIn: () async => null,
        ),
        home: const SizedBox.shrink(),
      ),
    );

    expect(
      find.byKey(const ValueKey('google-sign-in-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
