import 'package:flutter/foundation.dart';

enum NumberingGame {
  formulaWorkshop('formula_workshop', '수식 공방', '숫자 순서를 지켜 등식을 완성하세요.');

  const NumberingGame(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;

  static NumberingGame fromId(String? id) {
    return values.firstWhere(
      (game) => game.id == id,
      orElse: () => NumberingGame.formulaWorkshop,
    );
  }
}

enum NumberingDifficulty { easy, normal, hard, expert, master, grandmaster }

extension NumberingDifficultyLabel on NumberingDifficulty {
  String get label => switch (this) {
        NumberingDifficulty.easy => 'EASY',
        NumberingDifficulty.normal => 'NORMAL',
        NumberingDifficulty.hard => 'HARD',
        NumberingDifficulty.expert => 'EXPERT',
        NumberingDifficulty.master => 'MASTER',
        NumberingDifficulty.grandmaster => 'GRANDMASTER',
      };
}

NumberingDifficulty difficultyForRound(int round) {
  assert(round >= 1);
  if (round <= 10) return NumberingDifficulty.easy;
  if (round <= 30) return NumberingDifficulty.normal;
  if (round <= 60) return NumberingDifficulty.hard;
  if (round <= 100) return NumberingDifficulty.expert;
  if (round <= 150) return NumberingDifficulty.master;
  return NumberingDifficulty.grandmaster;
}

@immutable
class ValidationResult {
  const ValidationResult._({
    required this.valid,
    this.value,
    this.message,
  });

  const ValidationResult.success(int value) : this._(valid: true, value: value);

  const ValidationResult.failure(String message)
      : this._(valid: false, message: message);

  final bool valid;
  final int? value;
  final String? message;
}
