import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:numbering/l10n/app_translations.dart';
import 'package:numbering/theme/app_theme.dart';
import 'package:numbering/widgets/home_screen/login_sheet.dart';

/// Temporary preview entry point for the required-login screen only.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('ko', 'KR'),
      fallbackLocale: AppTranslations.fallback,
      theme: AppTheme.light,
      home: RequiredLoginScreen(
        onGoogleSignIn: () async => null,
        onAppleSignIn: () async => null,
      ),
    ),
  );
}
