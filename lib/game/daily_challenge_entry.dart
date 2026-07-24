import 'package:numbering/game/game_module.dart';
import 'package:numbering/services/database_models.dart';

class DailyChallengeLaunchDecision {
  const DailyChallengeLaunchDecision({
    required this.canLaunch,
    this.sessionConfig,
    this.noticeMessage,
  });

  final bool canLaunch;
  final GameSessionConfig? sessionConfig;
  final String? noticeMessage;
}

DailyChallengeLaunchDecision resolveDailyChallengeLaunch({
  required DailyChallengeInfo challenge,
  required bool isLoggedIn,
}) {
  if (!isLoggedIn) {
    return const DailyChallengeLaunchDecision(
      canLaunch: false,
      noticeMessage: '오늘의 퍼즐은 로그인 후 12시간마다 참여할 수 있어요.',
    );
  }

  if (challenge.hasUsedEntry) {
    return const DailyChallengeLaunchDecision(
      canLaunch: false,
      noticeMessage: '이번 12시간 퍼즐은 이미 참여했어요.',
    );
  }

  return DailyChallengeLaunchDecision(
    canLaunch: true,
    sessionConfig: GameSessionConfig(
      mode: GameMode.dailyOfficial,
      seed: challenge.seed,
      dateKey: challenge.dateKey,
      isOfficialScoreSubmission: true,
    ),
  );
}
