import 'game_module.dart';
import 'numbering/numbering_game_module.dart';
import 'numbering/numbering_models.dart';

/// Add the new game's import and assign its module here.
/// Everything outside the game slot can stay unchanged.
abstract final class GameRegistry {
  static const List<GameModule> modules = [
    NumberingGameModule(NumberingGame.formulaWorkshop),
  ];

  static GameModule byId(String? id) {
    return modules.firstWhere(
      (module) => module.id == id,
      orElse: () => modules.first,
    );
  }
}
