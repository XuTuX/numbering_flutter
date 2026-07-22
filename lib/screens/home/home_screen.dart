import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/audio_service.dart';
import 'package:numbering/services/database_models.dart';
import 'package:numbering/services/numbering_score_service.dart';

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
  late final Worker _dailyAuthWorker;
  bool _isNicknameDialogActive = false;
  DailyChallengeUiState _dailyState = DailyChallengeUiState.loading;
  DailyChallengeInfo? _dailyChallenge;
  int? _allTimeRank;
  int? _allTimeBest;

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
    _dailyAuthWorker = ever(authService.user, (_) {
      _loadDailyChallenge();
      _loadRankingSummary();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNicknameRequirement();
      unawaited(_loadDailyChallenge());
      unawaited(_loadRankingSummary());
      unawaited(AudioService().startHomeBGM());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileLoadedWorker.dispose();
    _userWorker.dispose();
    _loadingWorker.dispose();
    _dailyAuthWorker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(AudioService().resumeBGMIfNeeded());
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

  Future<void> _loadDailyChallenge() async {
    final authService = Get.find<AuthService>();
    if (authService.user.value == null) {
      if (mounted) {
        setState(() {
          _dailyState = DailyChallengeUiState.notAuthenticated;
          _dailyChallenge = null;
        });
      }
      return;
    }
    if (mounted) setState(() => _dailyState = DailyChallengeUiState.loading);
    try {
      final challenge =
          await Get.find<NumberingScoreService>().getDailyChallenge();
      if (!mounted) return;
      setState(() {
        _dailyChallenge = challenge;
        _dailyState = challenge.myScore == null
            ? DailyChallengeUiState.available
            : DailyChallengeUiState.alreadyPlayed;
      });
    } on NumberingServiceException {
      if (!mounted) return;
      setState(() => _dailyState = DailyChallengeUiState.networkError);
    }
  }

  Future<void> _loadRankingSummary() async {
    final service = Get.find<NumberingScoreService>();
    if (!service.isAuthenticated) {
      if (mounted) {
        setState(() {
          _allTimeRank = null;
          _allTimeBest = null;
        });
      }
      return;
    }
    try {
      final results = await Future.wait<int?>([
        service.getMyScore(functionName: 'get_my_rank'),
        service.getMyScore(functionName: 'get_my_best_score'),
      ]);
      if (!mounted) return;
      setState(() {
        _allTimeRank = results[0];
        _allTimeBest = results[1];
      });
    } on NumberingServiceException {
      // The ranking card remains available as a navigation action even when
      // its compact summary cannot be loaded.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final levelProgress = Get.find<LevelProgressService>();

    return Obx(() {
      final currentLevel = levelProgress.highestUnlockedLevel;
      final nickname = authService.user.value == null
          ? null
          : authService.userNickname.value;
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
        onStartDaily: () async {
          await openDailyChallenge(authService);
          await _loadDailyChallenge();
        },
        onRankingTap: handleRankingPress,
        dailyState: _dailyState,
        dailyDateKey: _dailyChallenge?.dateKey,
        dailyScore: _dailyChallenge?.myScore,
        allTimeRank: _allTimeRank,
        allTimeBest: _allTimeBest,
      );
    });
  }
}
