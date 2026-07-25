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
            SizedBox(height: isLandscape ? 4 : 8),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? (mediaSize.width * 0.82).clamp(540.0, 720.0) : 600.0,
                  ),
                  child: Obx(() {
                    final records = SimulationMode.isEnabled.value ? _getMockRecords() : scoreService.records;
                    final nickname = authService.userNickname.value ?? 'Player';
                    final myRank = SimulationMode.isEnabled.value ? 112 : scoreService.getMyRank(nickname);
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

                    final displayItems = _buildDisplayItems(
                      records: records,
                      myRank: myRank,
                      myBestRecord: myBestRecord,
                      nickname: nickname,
                    );

                    if (isLandscape) {
                      final half = (displayItems.length / 2).ceil();
                      final leftItems = displayItems.sublist(0, half);
                      final rightItems = displayItems.sublist(half);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                                  child: _buildRankListColumn(leftItems),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildRankListColumn(rightItems),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: displayItems.length + 1,
                      separatorBuilder: (context, index) {
                        if (index == 0) return const SizedBox(height: 12);
                        final currentItem = displayItems[index - 1];
                        final nextItem = index < displayItems.length ? displayItems[index] : null;
                        if (currentItem.isEllipsis || (nextItem != null && nextItem.isEllipsis)) {
                          return const SizedBox.shrink();
                        }
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
                        final item = displayItems[index - 1];
                        if (item.isEllipsis) {
                          return const _EllipsisDivider();
                        }
                        return _TimeAttackRankListItem(
                          rank: item.rank,
                          record: item.record!,
                          isMe: item.isMe,
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

  List<_RankDisplayItem> _buildDisplayItems({
    required List<TimeAttackRecord> records,
    required int? myRank,
    required TimeAttackRecord? myBestRecord,
    required String nickname,
  }) {
    final items = <_RankDisplayItem>[];
    bool meIncluded = false;

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final rank = i + 1;
      final isMe = (record.nickname == nickname) || (myRank == rank);
      if (isMe) meIncluded = true;
      items.add(_RankDisplayItem(rank: rank, record: record, isMe: isMe));
    }

    if (!meIncluded && myRank != null && myBestRecord != null) {
      items.add(const _RankDisplayItem(rank: 0, isEllipsis: true));
      items.add(_RankDisplayItem(
        rank: myRank,
        record: myBestRecord,
        isMe: true,
      ));
    }

    return items;
  }

  Widget _buildRankListColumn(List<_RankDisplayItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) {
        final currentItem = items[index];
        final nextItem = index + 1 < items.length ? items[index + 1] : null;
        if (currentItem.isEllipsis || (nextItem != null && nextItem.isEllipsis)) {
          return const SizedBox.shrink();
        }
        return const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.hairlineSoft,
        );
      },
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isEllipsis) {
          return const _EllipsisDivider();
        }
        return _TimeAttackRankListItem(
          rank: item.rank,
          record: item.record!,
          isMe: item.isMe,
        );
      },
    );
  }
}

class _RankDisplayItem {
  const _RankDisplayItem({
    required this.rank,
    this.record,
    this.isMe = false,
    this.isEllipsis = false,
  });

  final int rank;
  final TimeAttackRecord? record;
  final bool isMe;
  final bool isEllipsis;
}

class _EllipsisDivider extends StatelessWidget {
  const _EllipsisDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          '• • •',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
          ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blockLilac,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Text(
            rank != null ? '내 순위  #$rank' : '내 기록',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rank == null ? '기록 없음' : '${totalScore ?? 0}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.onPrimary,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.blockMint : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: AppColors.ink.withValues(alpha: 0.15), width: 1)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '$rank.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isMe ? AppColors.ink : AppColors.ink.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Flexible(
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
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMe ? 10 : 0,
              vertical: isMe ? 4 : 0,
            ),
            decoration: isMe
                ? BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Text(
              '${record.totalScore}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isMe ? AppColors.onPrimary : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
