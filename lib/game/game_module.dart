import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Launch modes supplied by the unchanged home, daily, and settings flows.
enum GameMode { normal, dailyPractice, dailyOfficial, replay, tutorial }

@immutable
class GameSessionConfig {
  const GameSessionConfig({
    required this.mode,
    this.gameId,
    this.seed,
    this.dateKey,
    this.weekKey,
    this.isOfficialScoreSubmission = false,
    this.startLevelId,
  });

  const GameSessionConfig.normal()
      : mode = GameMode.normal,
        gameId = null,
        seed = null,
        dateKey = null,
        weekKey = null,
        isOfficialScoreSubmission = false,
        startLevelId = null;

  final GameMode mode;
  final String? gameId;
  final int? seed;
  final String? dateKey;
  final String? weekKey;
  final bool isOfficialScoreSubmission;
  final int? startLevelId;

  bool get isTutorialMode => mode == GameMode.tutorial;
  bool get isDailyMode =>
      mode == GameMode.dailyPractice || mode == GameMode.dailyOfficial;

  String get modeLabel => switch (mode) {
        GameMode.normal => '일반 모드'.tr,
        GameMode.dailyPractice => '오늘의 퍼즐 연습'.tr,
        GameMode.dailyOfficial => '오늘의 퍼즐'.tr,
        GameMode.replay => '리플레이'.tr,
        GameMode.tutorial => '튜토리얼'.tr,
      };
}

@immutable
class GameResult {
  const GameResult({
    required this.score,
    this.detailLabel,
    this.detailValue,
  });

  final int score;
  final String? detailLabel;
  final String? detailValue;
}

class GameCallbacks {
  const GameCallbacks({
    required this.onScoreChanged,
    required this.onFinished,
    required this.onExit,
  });

  final ValueChanged<int> onScoreChanged;
  final ValueChanged<GameResult> onFinished;
  final VoidCallback onExit;
}

/// Implement only this contract when adding a new game.
abstract class GameModule {
  const GameModule();

  String get id;
  String get title;

  Widget build(
    BuildContext context,
    GameSessionConfig session,
    GameCallbacks callbacks,
  );
}
