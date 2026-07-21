import 'package:flutter/material.dart';

import '../game_module.dart';
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
}
