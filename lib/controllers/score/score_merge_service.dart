import 'dart:math';

/// Pure high-score bookkeeping logic, extracted out of [ScoreController]'s
/// `part` files so it can be unit tested directly — no GetX controller,
/// SharedPreferences, or widget test bootstrapping required.
class ScoreMergeService {
  const ScoreMergeService();

  /// The SharedPreferences key a user's high score is stored under.
  String storageKeyFor(String? userId) =>
      userId != null ? 'high_score_$userId' : 'high_score_guest';

  /// Decides the score to carry into a user's account on login, reconciling
  /// their existing per-account score with any pre-migration legacy score
  /// and any progress made while playing as a guest before signing in.
  int mergeOnLogin({
    required int userLocalScore,
    required int legacyScore,
    required int guestScore,
  }) {
    return [
      userLocalScore,
      legacyScore,
      guestScore,
    ].reduce(max);
  }
}
