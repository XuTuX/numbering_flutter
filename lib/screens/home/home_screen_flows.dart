import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/screens/game_screen.dart';
import 'package:numbering/screens/ranking/ranking_screen.dart';
import 'package:numbering/screens/settings/settings_screen.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/widgets/home_screen/login_sheet.dart';

void handleRankingPress() {
  showRankingSheet();
}

void openGameScreen(
    [GameSessionConfig sessionConfig = const GameSessionConfig.normal()]) {
  Get.off(
    () => GameScreen(sessionConfig: sessionConfig),
    transition: Transition.zoom,
    duration: const Duration(milliseconds: 250),
  );
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
  Get.to(
    () => const RankingScreen(),
    transition: Transition.zoom,
    duration: const Duration(milliseconds: 250),
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

Future<void> showEditNicknameDialog(AuthService authService) async {
  final nickname = authService.userNickname.value;
  if (authService.user.value == null || nickname == null) {
    return;
  }

  await Get.dialog(
    EditNicknameDialog(
      currentNickname: nickname,
      onSave: authService.updateNickname,
    ),
  );
}
