part of 'package:numbering/controllers/score_controller.dart';

Future<void> _syncWithOnlineScore(
  ScoreController controller,
  int localScore, {
  String? expectedUserId,
  int? expectedAuthSyncGeneration,
}) async {
  // Score storage is intentionally local. Supabase is used for auth only.
}

Future<void> _syncScoreForRanking(ScoreController controller) async {
  // Rankings are not connected to Supabase in the template.
}
