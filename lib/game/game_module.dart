import 'package:flutter/material.dart';

/// Launch modes supplied by the home and settings flows.
enum GameMode { normal, timeAttack, tutorial }

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
}

class GameCallbacks {
  const GameCallbacks({
    required this.onExit,
  });

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
