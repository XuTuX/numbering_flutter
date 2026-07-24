import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/audio_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/utils/app_snackbar.dart';

import 'home_screen_flows.dart';
import 'widgets/home_screen_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final Worker _profileLoadedWorker;
  late final Worker _userWorker;
  late final Worker _loadingWorker;
  bool _isNicknameDialogActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authService = Get.find<AuthService>();
    _profileLoadedWorker =
        ever(authService.isProfileLoaded, (_) => _checkNicknameRequirement());
    _userWorker = ever(authService.user, (_) => _checkNicknameRequirement());
    _loadingWorker =
        ever(authService.isLoading, (_) => _checkNicknameRequirement());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNicknameRequirement();
      unawaited(AudioService().startHomeBGM());

      if (Get.isRegistered<HintService>()) {
        final hintService = Get.find<HintService>();
        if (hintService.justReceivedAttendanceBonus.value) {
          hintService.justReceivedAttendanceBonus.value = false;
          showAppSnackBar(
            title: '출석 보상',
            message: '오늘의 출석 보상! 힌트 +3개가 추가되었습니다. 💡',
            icon: Icons.lightbulb_rounded,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileLoadedWorker.dispose();
    _userWorker.dispose();
    _loadingWorker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(AudioService().resumeBGMIfNeeded());
        if (Get.isRegistered<HintService>()) {
          final hintService = Get.find<HintService>();
          hintService.checkDailyAttendance().then((_) {
            if (hintService.justReceivedAttendanceBonus.value && mounted) {
              hintService.justReceivedAttendanceBonus.value = false;
              showAppSnackBar(
                title: '출석 보상',
                message: '오늘의 출석 보상! 힌트 +3개가 추가되었습니다. 💡',
                icon: Icons.lightbulb_rounded,
              );
            }
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(AudioService().pauseBGM());
        break;
    }
  }

  Future<void> _checkNicknameRequirement() async {
    final authService = Get.find<AuthService>();
    final needsNickname = !authService.isLoading.value &&
        authService.user.value != null &&
        authService.isProfileLoaded.value &&
        !authService.hasProfileLoadError.value &&
        authService.userNickname.value == null;

    if (!needsNickname) {
      return;
    }
    if (_isNicknameDialogActive || Get.isDialogOpen == true) {
      return;
    }

    debugPrint('Force showing nickname dialog due to missing nickname');
    _isNicknameDialogActive = true;
    try {
      await showInitialNicknameDialog(authService);
    } finally {
      _isNicknameDialogActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final levelProgress = Get.find<LevelProgressService>();
    final timeAttackService = Get.isRegistered<TimeAttackScoreService>()
        ? Get.find<TimeAttackScoreService>()
        : null;

    return Obx(() {
      final currentLevel = levelProgress.highestUnlockedLevel;
      final nickname = authService.user.value == null
          ? null
          : authService.userNickname.value;
      final bestRecord = timeAttackService?.personalBest;
      final myRank = nickname == null ? null : timeAttackService?.getMyRank(nickname);

      return HomeScreenContent(
        nickname: nickname,
        onNicknameTap:
            nickname == null ? null : () => showEditNicknameDialog(authService),
        currentLevel: currentLevel,
        onSettingsTap: () => showSettingsScreen(authService),
        onStartGame: () => openGameScreen(
          GameSessionConfig(
            mode: GameMode.normal,
            startLevelId: currentLevel,
          ),
        ),
        onStartTimeAttack: () => openGameScreen(
          const GameSessionConfig.timeAttack(),
        ),
        onRankingTap: showRankingSheet,
        rank: myRank,
        bestNumber: bestRecord?.highestNumber,
        topScore: bestRecord?.totalScore,
      );
    });
  }
}
