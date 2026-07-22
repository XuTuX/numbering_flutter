import 'package:flutter/material.dart';

import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/services/numbering_score_service.dart';

class RankListItem extends StatelessWidget {
  const RankListItem({
    super.key,
    required this.scoreData,
    required this.myId,
  });

  final NumberingLeaderboardEntry scoreData;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final nickname = scoreData.nickname;
    final score = scoreData.score;
    final userId = scoreData.userId;
    final isMe = userId == myId;
    final rank = scoreData.rank;

    // Top 3 get pastel backgrounds matching the home screen design tokens
    final Color bgColor;
    final Color rankColor;
    if (rank == 1) {
      bgColor = AppColors.blockLilac;
      rankColor = AppColors.ink;
    } else if (rank == 2) {
      bgColor = AppColors.blockLime;
      rankColor = AppColors.ink;
    } else if (rank == 3) {
      bgColor = AppColors.blockCream;
      rankColor = AppColors.ink;
    } else if (isMe) {
      bgColor = AppColors.surfaceSoft;
      rankColor = AppColors.ink;
    } else {
      bgColor = AppColors.canvas;
      rankColor = AppColors.ink.withValues(alpha: 0.3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: rank > 3 ? Border.all(color: AppColors.hairline) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isMe)
                  Text(
                    'YOU',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink.withValues(alpha: 0.4),
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatScore(score),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int value) {
    if (value < 1000) return value.toString();
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
