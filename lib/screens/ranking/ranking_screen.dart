import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/simulation_mode.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({
    super.key,
    this.showCloseButton = false,
  });

  final bool showCloseButton;

  List<TimeAttackRecord> _getMockRecords() {
    final now = DateTime.now();
    return List.generate(10, (index) {
      return TimeAttackRecord(
        id: 'mock_${index + 1}',
        nickname: 'Player${index + 1}',
        highestNumber: 1000 - (index * 50),
        totalScore: 15000 - (index * 1000),
        achievedAt: now.subtract(Duration(minutes: index * 10)),
        playedAt: now.subtract(Duration(minutes: index * 10)),
      );
    });
  }

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
        leading: showCloseButton
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
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
                    maxWidth: isLandscape ? (mediaSize.width * 0.82).clamp(540.0, 720.0) : 480.0,
                  ),
                  child: Obx(() {
                    final records = SimulationMode.isEnabled.value ? _getMockRecords() : scoreService.records;
                    final nickname = authService.userNickname.value ?? 'Player';
                    final myRank = SimulationMode.isEnabled.value ? 5 : scoreService.getMyRank(nickname);
                    final myBestRecord = SimulationMode.isEnabled.value
                        ? TimeAttackRecord(
                            id: 'mock_my_best',
                            nickname: nickname,
                            highestNumber: 800,
                            totalScore: 11000,
                            achievedAt: DateTime.now(),
                            playedAt: DateTime.now(),
                          )
                        : scoreService.personalBest;

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

                    if (isLandscape) {
                      final half = (records.length / 2).ceil();
                      final leftRecords = records.sublist(0, half);
                      final rightRecords = records.sublist(half);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                        child: Column(
                          children: [
                            _MyRankBar(
                              rank: myRank,
                              bestNumber: myBestRecord?.highestNumber,
                              totalScore: myBestRecord?.totalScore,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildRankListColumn(
                                    records: leftRecords,
                                    startIndex: 1,
                                    nickname: nickname,
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildRankListColumn(
                                    records: rightRecords,
                                    startIndex: half + 1,
                                    nickname: nickname,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      itemCount: records.length + 1,
                      separatorBuilder: (context, index) {
                        if (index == 0) return const SizedBox(height: 12);
                        return const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.hairlineSoft,
                        );
                      },
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

  Widget _buildRankListColumn({
    required List<TimeAttackRecord> records,
    required int startIndex,
    required String nickname,
  }) {
    if (records.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.hairlineSoft,
      ),
      itemBuilder: (context, index) {
        final record = records[index];
        final rank = startIndex + index;
        return _TimeAttackRankListItem(
          rank: rank,
          record: record,
          isMe: record.nickname == nickname,
        );
      },
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.blockMint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text(
            '내 기록',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          Text(
            rank == null ? '기록 없음' : '${totalScore ?? 0}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.ink,
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.blockLilac.withValues(alpha: 0.6) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$rank.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isMe ? AppColors.ink : AppColors.ink.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              record.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${record.totalScore}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
