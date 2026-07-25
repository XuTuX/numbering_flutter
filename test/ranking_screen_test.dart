import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:numbering/screens/ranking/ranking_screen.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    final auth = Get.put<AuthService>(AuthService());
    auth.userNickname.value = '나';
    final scores = Get.put<TimeAttackScoreService>(_RankingTimeAttackService());
    scores.records.assignAll(<TimeAttackRecord>[
      _record(userId: 'first', nickname: '첫째', rank: 1),
      _record(userId: 'second', nickname: '둘째', rank: 2),
      _record(userId: 'me', nickname: '나', rank: 150, isMe: true),
    ]);
    scores.myRank.value = 150;
  });

  tearDown(Get.reset);

  testWidgets('uses server ranks and does not duplicate a user outside top 100',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const GetMaterialApp(home: RankingScreen()),
    );
    await tester.pump();

    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('150.'), findsOneWidget);
    expect(find.text('3.'), findsNothing);
    // Once in the personal bar and once in the ranked list.
    expect(find.text('나'), findsNWidgets(2));
  });
}

TimeAttackRecord _record({
  required String userId,
  required String nickname,
  required int rank,
  bool isMe = false,
}) {
  return TimeAttackRecord(
    userId: userId,
    nickname: nickname,
    highestNumber: 10,
    totalScore: 20,
    highestAchievedAt: DateTime.utc(2026),
    achievedAt: DateTime.utc(2026),
    rank: rank,
    isMe: isMe,
  );
}

class _RankingTimeAttackService extends TimeAttackScoreService {
  @override
  Future<void> refreshLeaderboard({int limit = 100}) async {}
}
