import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/theme/app_colors.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({
    super.key,
    this.showCloseButton = false,
  });

  final bool showCloseButton;

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
                    maxWidth: isLandscape
                        ? (mediaSize.width * 0.82).clamp(500.0, 640.0)
                        : 600.0,
                  ),
                  child: Obx(() {
                    final records = scoreService.records;
                    final nickname = authService.userNickname.value ?? 'Player';
                    final myRank = scoreService.myRank.value;
                    final myBestRecord = scoreService.personalBest;

                    if (records.isEmpty) {
                      return const Center(
                        child: Text(
                          '기록 없음',
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
                    );

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: displayItems.length + 1,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 4);
                      },
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return FractionallySizedBox(
                            widthFactor: 2 / 3,
                            child: _MyRankBar(
                              nickname: nickname,
                              rank: myRank,
                              totalScore: myBestRecord?.totalScore,
                            ),
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
  }) {
    final items = <_RankDisplayItem>[];
    bool meIncluded = false;
    final includedUserIds = <String>{};

    for (final record in records) {
      if (!includedUserIds.add(record.userId)) continue;
      final rank = record.rank;
      final isMe = record.isMe || (myRank != null && rank == myRank);
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
    required this.nickname,
    required this.rank,
    required this.totalScore,
  });

  final String nickname;
  final int? rank;
  final int? totalScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.blockMint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
        color: isMe
            ? AppColors.blockLilac.withValues(alpha: 0.6)
            : Colors.transparent,
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
                color: isMe
                    ? AppColors.ink
                    : AppColors.ink.withValues(alpha: 0.75),
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
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: isMe ? AppColors.primary : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
