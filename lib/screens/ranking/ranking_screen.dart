import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/theme/app_colors.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final authService = Get.find<AuthService>();
    final scoreService = Get.find<TimeAttackScoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'TIME ATTACK RANKING',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: isLandscape ? 8 : 16),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? mediaSize.width * 0.85 : 480,
                  ),
                  child: Obx(() {
                    final records = scoreService.records;
                    final nickname = authService.userNickname.value ?? 'Player';
                    final myRank = scoreService.getMyRank(nickname);
                    final myBestRecord = scoreService.personalBest;

                    if (records.isEmpty) {
                      return const Center(
                        child: Text(
                          '아직 기록이 없습니다.\nTime Attack을 플레이해 첫 기록을 달성해 보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: records.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _MyRankBar(
                            rank: myRank,
                            bestNumber: myBestRecord?.highestNumber,
                            totalScore: myBestRecord?.totalScore,
                          );
                        }
                        final record = records[index - 1];
                        return _TimeAttackRankListItem(
                          rank: index,
                          record: record,
                          isMe: record.nickname == nickname,
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRankBar extends StatelessWidget {
  const _MyRankBar({
    required this.rank,
    required this.bestNumber,
    required this.totalScore,
  });

  final int? rank;
  final int? bestNumber;
  final int? totalScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.blockMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          const Text('내 기록', style: TextStyle(fontWeight: FontWeight.w900)),
          const Spacer(),
          Text(
            rank == null
                ? '기록 없음'
                : '#$rank · BEST ${bestNumber ?? 0} · ${totalScore ?? 0}점',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TimeAttackRankListItem extends StatelessWidget {
  const _TimeAttackRankListItem({
    required this.rank,
    required this.record,
    required this.isMe,
  });

  final int rank;
  final TimeAttackRecord record;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${record.playedAt.year}.${record.playedAt.month.toString().padLeft(2, '0')}.${record.playedAt.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.blockLilac : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.ink : AppColors.hairline,
          width: isMe ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'BEST ${record.highestNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'TOP SCORE ${record.totalScore}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
