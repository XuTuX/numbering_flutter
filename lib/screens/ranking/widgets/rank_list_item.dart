import 'package:flutter/material.dart';

import 'package:numbering/theme/app_colors.dart';

class RankListItem extends StatelessWidget {
  const RankListItem({
    super.key,
    required this.scoreData,
    required this.index,
    required this.myId,
  });

  final Map<String, dynamic> scoreData;
  final int index;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final profileData = scoreData['profiles'];
    Map<String, dynamic> profiles = {};
    if (profileData is Map<String, dynamic>) {
      profiles = profileData;
    } else if (profileData is List && profileData.isNotEmpty) {
      profiles = profileData[0] as Map<String, dynamic>;
    }

    final nickname = profiles['nickname'] ?? 'Player';
    final scoreVal = scoreData['score'];
    final score = _parseScore(scoreVal);
    final userId = scoreData['user_id'];
    final isMe = userId != null && userId == myId;
    final rankValue = scoreData['rank'];
    final rank = switch (rankValue) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? (index + 1),
      _ => index + 1,
    };

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

  String _formatScore(dynamic score) {
    final value = _parseScore(score);
    if (value < 1000) return value.toString();
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  int _parseScore(dynamic score) {
    return score is int ? score : int.tryParse(score.toString()) ?? 0;
  }
}


