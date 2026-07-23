import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:numbering/constant.dart';
import 'package:numbering/config/app_config.dart';
import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/l10n/app_translations.dart';
import 'package:numbering/screens/home/home_screen.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/numbering_score_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/services/settings_service.dart';
import 'package:numbering/services/ad_service.dart';
import 'package:numbering/services/audio_service.dart';
import 'package:numbering/controllers/daily_puzzle_controller.dart';
import 'package:numbering/utils/app_snackbar.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_shadows.dart';
import 'package:numbering/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();

  // 레벨 그리드와 퍼즐 편집기는 세로·가로 모바일 화면을 모두 지원합니다.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final settingsService = await SettingsService().init();
  final levelProgressService = await LevelProgressService().init();
  final hintService = await HintService().init();
  await AudioService().initialize(
    isBgmEnabled: settingsService.isBgmOn.value,
    isSfxEnabled: settingsService.isSfxOn.value,
  );
  try {
    AppConfig.validateRequired();

    if (AppConfig.supportsAds) {
      try {
        await _configureFamilySafeAds();
        await MobileAds.instance.initialize();
      } catch (error, stackTrace) {
        debugPrint('Ads unavailable; continuing without ads: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    SupabaseClient? authClient;
    if (AppConfig.hasSupabaseConfig) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
        authClient = Supabase.instance.client;
      } catch (error, stackTrace) {
        debugPrint(
          'Supabase unavailable; continuing in offline guest mode: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    } else {
      debugPrint('Supabase config omitted; starting in offline guest mode.');
    }

    runApp(
      NumberingApp(
        settingsService: settingsService,
        levelProgressService: levelProgressService,
        hintService: hintService,
        authClient: authClient,
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize app: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      ConfigurationErrorApp(
        message: error is StateError ? error.message : error.toString(),
      ),
    );
  }
}

Future<void> _configureFamilySafeAds() {
  return MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      maxAdContentRating: MaxAdContentRating.g,
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
    ),
  );
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 [FlutterError] ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('🔴 [PlatformDispatcher] $error');
    debugPrintStack(stackTrace: stackTrace);
    return true;
  };
}

class AppBinding extends Bindings {
  final SettingsService settingsService;
  final LevelProgressService levelProgressService;
  final HintService hintService;
  final SupabaseClient? authClient;

  AppBinding({
    required this.settingsService,
    required this.levelProgressService,
    required this.hintService,
    required this.authClient,
  });

  @override
  void dependencies() {
    Get.put(AuthService(supabase: authClient), permanent: true);
    Get.put(NumberingScoreService(supabase: authClient), permanent: true);
    Get.put(ScoreController(), permanent: true);
    Get.put(DailyPuzzleController(), permanent: true);
    if (AppConfig.supportsAds) {
      Get.put(AdService(), permanent: true);
    }
    Get.put<SettingsService>(settingsService, permanent: true);
    Get.put<LevelProgressService>(levelProgressService, permanent: true);
    Get.put<HintService>(hintService, permanent: true);
  }
}

class NumberingApp extends StatelessWidget {
  final SettingsService settingsService;
  final LevelProgressService levelProgressService;
  final HintService hintService;
  final SupabaseClient? authClient;

  const NumberingApp({
    super.key,
    required this.settingsService,
    required this.levelProgressService,
    required this.hintService,
    required this.authClient,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      initialBinding: AppBinding(
        settingsService: settingsService,
        levelProgressService: levelProgressService,
        hintService: hintService,
        authClient: authClient,
      ),
      navigatorKey: Get.key, // GetX 글로벌 키 설정
      translations: AppTranslations(),
      theme: AppTheme.light,
      locale: settingsService.locale.value,
      fallbackLocale: AppTranslations.fallback,
      home: const HomeScreen(),
    );
  }
}

class ConfigurationErrorApp extends StatelessWidget {
  final String message;

  const ConfigurationErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppShadows.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'APP CONFIGURATION NEEDED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Provide both Supabase values, or omit both to use '
                      'offline guest mode.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
