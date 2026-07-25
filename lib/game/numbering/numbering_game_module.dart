import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../screens/home/level_list_screen.dart';
import '../../screens/home/widgets/home_screen_content.dart';
import '../game_module.dart';
import 'level_progress_service.dart';
import 'numbering_game_page.dart';
import 'numbering_models.dart';

class NumberingGameModule extends GameModule {
  const NumberingGameModule(this.game);

  final NumberingGame game;

  @override
  String get id => game.id;

  @override
  String get title => game.title;

  @override
  Widget build(
    BuildContext context,
    GameSessionConfig session,
    GameCallbacks callbacks,
  ) {
    return NumberingGamePage(
      game: game,
      session: session,
      callbacks: callbacks,
    );
  }

  @override
  void exitToModuleHome(BuildContext context, GameSessionConfig session) {
    final levelId = Get.find<LevelProgressService>().lastPlayedLevel.value;
    Get.off(
      () => LevelListScreen(pack: levelPackFor(levelId)),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 220),
    );
  }
}
