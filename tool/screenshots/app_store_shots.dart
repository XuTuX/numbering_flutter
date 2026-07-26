// Cycles through production screens with deterministic local data so App Store
// screenshots can be captured without using a real account or live services.
//
// flutter build ios --simulator --debug -t tool/screenshots/app_store_shots.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/l10n/app_translations.dart';
import 'package:numbering/screens/game_screen.dart';
import 'package:numbering/screens/hints/hint_store_screen.dart';
import 'package:numbering/screens/home/arcade_screen.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';
import 'package:numbering/screens/ranking/ranking_screen.dart';
import 'package:numbering/services/audio_service.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/hint_purchase_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService().initialize(isBgmEnabled: false, isSfxEnabled: false);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final progress = await LevelProgressService().init();
  progress.progress.assignAll({
    for (var level = 1; level <= 12; level++)
      level: LevelProgress(
        levelId: level,
        cleared: true,
        bestScore: 1000 - level * 7,
        stars: 3,
        perfect: true,
        usedHints: 0,
      ),
  });
  progress.lastPlayedLevel.value = 13;

  final hints = await HintService().init();
  hints.hints.value = 23;
  final purchases = HintPurchaseService(hintService: hints)
    ..isStoreAvailable.value = true
    ..products.assignAll([
      for (final pack in hintPacks)
        ProductDetails(
          id: pack.productId,
          title: '힌트 ${pack.hintCount}개',
          description: '',
          price: pack.fallbackPrice,
          rawPrice: pack.plannedKrwPrice.toDouble(),
          currencyCode: 'KRW',
        ),
    ]);

  final auth = AuthService()..userNickname.value = 'NUMBERING';
  final scores = _ScreenshotTimeAttackService();
  scores.records.assignAll([
    _record('logic', '수식왕', 1, 2640),
    _record('zero', '제로', 2, 2410),
    _record('numbering', 'NUMBERING', 3, 2280, isMe: true),
    _record('mint', '민트', 4, 2190),
    _record('puzzle', '퍼즐러', 5, 2070),
  ]);
  scores.myRank.value = 3;

  Get.put<LevelProgressService>(progress, permanent: true);
  Get.put<HintService>(hints, permanent: true);
  Get.put<HintPurchaseService>(purchases, permanent: true);
  Get.put<AuthService>(auth, permanent: true);
  Get.put<TimeAttackScoreService>(scores, permanent: true);

  const requestedIndex = int.fromEnvironment('SHOT_INDEX', defaultValue: -1);
  final preferences = await SharedPreferences.getInstance();
  final screenIndex = requestedIndex >= 0
      ? requestedIndex
      : preferences.getInt('app_store_shot_index') ?? 0;
  runApp(_ScreenshotApp(screenIndex: screenIndex.clamp(0, 5)));
}

TimeAttackRecord _record(
  String userId,
  String nickname,
  int rank,
  int totalScore, {
  bool isMe = false,
}) {
  return TimeAttackRecord(
    userId: userId,
    nickname: nickname,
    highestNumber: 12,
    totalScore: totalScore,
    highestAchievedAt: DateTime.utc(2026, 7, 27),
    achievedAt: DateTime.utc(2026, 7, 27),
    rank: rank,
    isMe: isMe,
  );
}

class _ScreenshotTimeAttackService extends TimeAttackScoreService {
  @override
  Future<void> refreshLeaderboard({int limit = 100}) async {}

  @override
  Future<TimeAttackSession> startSession() async {
    return TimeAttackSession(
      id: 'app-store-screenshot',
      digits: '4186',
      puzzleIndex: 0,
      highestNumber: 12,
      totalScore: 2280,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 3)),
      remainingMilliseconds: 180000,
    );
  }
}

class _ScreenshotApp extends StatelessWidget {
  const _ScreenshotApp({required this.screenIndex});

  final int screenIndex;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light;
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('ko', 'KR'),
      fallbackLocale: AppTranslations.fallback,
      theme: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: _ScreenshotDeck(screenIndex: screenIndex),
    );
  }
}

class _ScreenshotDeck extends StatelessWidget {
  const _ScreenshotDeck({required this.screenIndex});

  final int screenIndex;

  static final List<Widget> _screens = [
    HomeScreenContent(
      onSettingsTap: () {},
      onStartGame: () {},
      onStartTimeAttack: () {},
      onRankingTap: () {},
      onNicknameTap: () {},
    ),
    ArcadeScreen(onStartGame: () {}),
    const GameScreen(
      sessionConfig: GameSessionConfig(
        mode: GameMode.normal,
        startLevelId: 13,
      ),
    ),
    const GameScreen(
      sessionConfig: GameSessionConfig(mode: GameMode.timeAttack),
    ),
    const RankingScreen(),
    const HintStoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return _screens[screenIndex];
  }
}
