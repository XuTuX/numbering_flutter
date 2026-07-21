import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/game/game_module.dart';
import 'package:hexor/game/numbering/numbering_models.dart';
import 'package:hexor/screens/game_screen.dart';
import 'package:hexor/screens/ranking_screen.dart';
import 'package:hexor/screens/settings_screen.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/utils/app_snackbar.dart';
import 'package:hexor/utils/kst_clock.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/home_screen/login_sheet.dart';

void handleRankingPress() {
  showRankingSheet();
}

void openGameScreen(
    [GameSessionConfig sessionConfig = const GameSessionConfig.normal()]) {
  Get.off(() => GameScreen(sessionConfig: sessionConfig));
}

Future<void> openDailyChallenge(AuthService authService) async {
  if (authService.user.value == null) {
    showLoginSheet(
      authService,
      initialError: '로그인이 필요합니다.'.tr,
    );
    return;
  }

  final dateKey = KstClock.currentDateKey();
  final seed = _localDailySeed(dateKey);
  openGameScreen(
    GameSessionConfig(
      mode: GameMode.dailyOfficial,
      gameId: _dailyGame(seed).id,
      seed: seed,
      dateKey: dateKey,
    ),
  );
}

Future<void> openDailyChallengeTest() async {
  final dateKey = KstClock.currentDateKey();
  final seed = _localDailySeed(dateKey);
  showAppSnackBar(
    title: '테스트 모드'.tr,
    message: '공식 기록 없이 오늘의 퍼즐을 테스트합니다.'.tr,
  );
  openGameScreen(
    GameSessionConfig(
      mode: GameMode.dailyPractice,
      gameId: _dailyGame(seed).id,
      seed: seed,
      dateKey: dateKey,
    ),
  );
}

int _localDailySeed(String dateKey) {
  return int.tryParse(dateKey.replaceAll('-', '')) ?? 0;
}

NumberingGame _dailyGame(int seed) {
  return NumberingGame.values[seed.abs() % NumberingGame.values.length];
}

void showLoginSheet(
  AuthService authService, {
  bool isRankingAction = false,
  String? initialError,
  VoidCallback? onRankingLoginSuccess,
}) {
  Get.bottomSheet(
    LoginSheet(
      isRankingAction: isRankingAction,
      initialError: initialError,
      onGoogleSignIn: authService.signInWithGoogle,
      onAppleSignIn: authService.signInWithApple,
      onLoginSuccess: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (isRankingAction) {
          (onRankingLoginSuccess ?? showRankingSheet)();
        }
      },
    ),
    isScrollControlled: true,
  );
}

void showSettingsScreen(AuthService authService) {
  Get.to(
    () => SettingsScreen(authService: authService),
    transition: Transition.rightToLeft,
    duration: const Duration(milliseconds: 300),
  );
}

void showRankingSheet() {
  Get.bottomSheet(
    const RankingScreen(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enterBottomSheetDuration: const Duration(milliseconds: 300),
  );
}

void showDailyRankingSheet({String? dateKey}) {
  Get.bottomSheet(
    RankingScreen(isDailyOnly: true, dailyDateKey: dateKey),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enterBottomSheetDuration: const Duration(milliseconds: 300),
  );
}

Future<void> showInitialNicknameDialog(AuthService authService) async {
  await Get.dialog(
    EditNicknameDialog(
      currentNickname: '',
      isInitialSetup: true,
      onSave: authService.updateNickname,
    ),
    barrierDismissible: false,
  );
}
