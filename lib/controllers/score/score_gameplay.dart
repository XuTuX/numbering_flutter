part of 'package:hexor/controllers/score_controller.dart';

void _registerPuzzleMatch(
  ScoreController controller, {
  required int points,
  required int comboDepth,
}) {
  controller.score.value += points;
  controller.combo.value = comboDepth;

  controller.checkHighScore();
}

void _resetScoreState(ScoreController controller) {
  controller.score.value = 0;
  controller.combo.value = 0;
  controller.hasNewHighScoreThisGame.value = false;
}

Future<void> _checkHighScore(ScoreController controller) async {
  if (controller.score.value > controller.highscore.value) {
    controller.highscore.value = controller.score.value;
    controller.hasNewHighScoreThisGame.value = true;
    await _saveHighScore(controller, controller.highscore.value);
  }
}
