import 'package:get/get.dart';

import 'package:hexor/game/game_module.dart';
import 'package:hexor/services/database_models.dart';

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
    return DailyChallengeLaunchDecision(
      canLaunch: false,
      noticeMessage: '오늘의 퍼즐은 로그인 후 하루 한 번만 참여할 수 있어요.'.tr,
    );
  }

  if (challenge.hasUsedEntry) {
    return DailyChallengeLaunchDecision(
      canLaunch: false,
      noticeMessage: '오늘의 퍼즐은 하루에 한 번만 가능해요.'.tr,
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
