import 'package:flutter/foundation.dart';

enum NumberingGame {
  formulaWorkshop('formula_workshop', '수식 공방', '숫자 순서를 지켜 등식을 완성하세요.'),
  sequenceDetective('sequence_detective', '수열 탐정', '마지막 값으로 시작 숫자를 추리하세요.'),
  numberVault('number_vault', '숫자 금고', '모든 숫자를 조합해 목표값을 만드세요.');

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

enum NumberingDifficulty { easy, normal, hard }

extension NumberingDifficultyLabel on NumberingDifficulty {
  String get label => switch (this) {
        NumberingDifficulty.easy => 'EASY',
        NumberingDifficulty.normal => 'NORMAL',
        NumberingDifficulty.hard => 'HARD',
      };
}

NumberingDifficulty difficultyForRound(int round) {
  assert(round >= 1);
  if (round <= 2) return NumberingDifficulty.easy;
  if (round <= 4) return NumberingDifficulty.normal;
  return NumberingDifficulty.hard;
}

int sequenceTermCountForRound(int round) {
  assert(round >= 1);
  if (round <= 2) return 5;
  if (round <= 4) return 6;
  if (round <= 6) return 7;
  return 8;
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
