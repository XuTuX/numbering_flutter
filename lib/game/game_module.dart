import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Launch modes supplied by the home and settings flows.
enum GameMode { normal, timeAttack, replay, tutorial }

@immutable
class GameSessionConfig {
  const GameSessionConfig({
    required this.mode,
    this.gameId,
    this.startLevelId,
  });

  const GameSessionConfig.normal()
      : mode = GameMode.normal,
        gameId = null,
        startLevelId = null;

  const GameSessionConfig.timeAttack()
      : mode = GameMode.timeAttack,
        gameId = null,
        startLevelId = null;

  final GameMode mode;
  final String? gameId;
  final int? startLevelId;

  bool get isTutorialMode => mode == GameMode.tutorial;
  bool get isTimeAttackMode => mode == GameMode.timeAttack;

  String get modeLabel => switch (mode) {
        GameMode.normal => '일반 모드'.tr,
        GameMode.timeAttack => 'Time Attack'.tr,
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

  /// Where "back" should take the player after a session GameScreen doesn't
  /// already handle generically (Time Attack always returns home).
  /// Each module owns its own post-game navigation (e.g. a level list),
  /// so adding a new game never requires editing GameScreen itself.
  void exitToModuleHome(BuildContext context, GameSessionConfig session);
}
