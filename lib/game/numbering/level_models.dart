import 'package:flutter/foundation.dart';

@immutable
class LevelHints {
  const LevelHints({
    required this.first,
    required this.second,
    required this.third,
  });

  final String first;
  final String second;
  final String third;

  String at(int index) => switch (index) {
        0 => first,
        1 => second,
        _ => third,
      };
}

@immutable
class LevelData {
  const LevelData({
    required this.id,
    required this.digitString,
    required this.availableOperators,
    required this.minimumScore,
    required this.targetScore,
    required this.officialAnswer,
    required this.hints,
    required this.difficulty,
    this.perfectAnswer,
    this.possiblePerfectScore,
  });

  final int id;
  final String digitString;
  final Set<String> availableOperators;
  final int minimumScore;
  final int targetScore;
  final String officialAnswer;
  final String? perfectAnswer;
  final int? possiblePerfectScore;
  final LevelHints hints;
  final int difficulty;

  List<String> get digits => digitString.split('');
}

@immutable
class LevelProgress {
  const LevelProgress({
    required this.levelId,
    this.cleared = false,
    this.bestScore,
    this.stars = 0,
    this.perfect = false,
    this.usedHints = 0,
  });

  final int levelId;
  final bool cleared;
  final int? bestScore;
  final int stars;
  final bool perfect;
  final int usedHints;

  Map<String, Object?> toJson() => {
        'levelId': levelId,
        'cleared': cleared,
        'bestScore': bestScore,
        'stars': stars,
        'perfect': perfect,
        'usedHints': usedHints,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'] as int,
      cleared: json['cleared'] as bool? ?? false,
      bestScore: json['bestScore'] as int?,
      stars: json['stars'] as int? ?? 0,
      perfect: json['perfect'] as bool? ?? false,
      usedHints: json['usedHints'] as int? ?? 0,
    );
  }
}

@immutable
class LevelEvaluation {
  const LevelEvaluation({
    required this.cleared,
    required this.stars,
    required this.perfect,
  });

  final bool cleared;
  final int stars;
  final bool perfect;
}

LevelEvaluation evaluateLevelScore(LevelData level, int score, {int usedHints = 0}) {
  bool cleared = true;
  int stars = 1;
  bool perfect = false;

  if (score < level.minimumScore) {
    cleared = false;
    stars = 0;
  } else if (score == level.minimumScore) {
    stars = 1;
  } else if (score < level.targetScore) {
    stars = 2;
  } else if (score == level.targetScore) {
    stars = 3;
  } else {
    stars = 3;
    perfect = true;
  }

  if (usedHints > 0) {
    if (stars > 2) {
      stars = 2;
    }
    perfect = false;
  }

  return LevelEvaluation(cleared: cleared, stars: stars, perfect: perfect);
}
