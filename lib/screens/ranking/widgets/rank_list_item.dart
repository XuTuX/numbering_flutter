import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/services/database_models.dart';
import 'package:numbering/theme/app_typography.dart';

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
    final tier = SeasonTier.fromScore(score);
    final frameStyle = _RankFrameStyle.forTier(tier);
    final hasTierFrame = frameStyle != null;
    final rankValue = scoreData['rank'];
    final rank = switch (rankValue) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? (index + 1),
      _ => index + 1,
    };

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFFB7185), // Coral Red
      2 => const Color(0xFFFB923C), // Orange
      3 => const Color(0xFFFBBF24), // Amber Yellow
      _ => charcoalBlack.withValues(alpha: 0.25),
    };

    Color itemBgColor = const Color(0xFFF8FAFC);
    Color borderColor = charcoalBlack.withValues(alpha: 0.08);

    if (isMe) {
      itemBgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFF2563EB).withValues(alpha: 0.2);
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: frameStyle?.backgroundColor ?? itemBgColor,
        borderRadius: BorderRadius.circular(hasTierFrame ? 12 : 14),
        border: hasTierFrame
            ? null
            : Border.all(
                color: borderColor,
                width: 1,
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$rank',
              style: GoogleFonts.blackHanSans(
                fontSize: 18,
                color: frameStyle?.rankColor ?? rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nickname,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                          color: charcoalBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isMe)
                  Text(
                    'YOU',
                    style: AppTypography.label.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2563EB),
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatScore(score),
            style: GoogleFonts.blackHanSans(
              fontSize: 15,
              color: frameStyle?.scoreColor ??
                  charcoalBlack.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );

    if (hasTierFrame) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: frameStyle.borderColors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: frameStyle.glowColor.withValues(alpha: 0.32),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: content,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: content,
    );
  }

  String _formatScore(dynamic score) {
    final value = _parseScore(score);
    if (value < 1000) {
      return value.toString();
    }

    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }

  int _parseScore(dynamic score) {
    return score is int ? score : int.tryParse(score.toString()) ?? 0;
  }
}

class _RankFrameStyle {
  const _RankFrameStyle({
    required this.borderColors,
    required this.backgroundColor,
    required this.rankColor,
    required this.scoreColor,
    required this.iconColor,
    required this.glowColor,
  });

  final List<Color> borderColors;
  final Color backgroundColor;
  final Color rankColor;
  final Color scoreColor;
  final Color iconColor;
  final Color glowColor;

  static _RankFrameStyle? forTier(SeasonTier tier) {
    return switch (tier) {
      SeasonTier.jesus => const _RankFrameStyle(
          borderColors: [
            Color(0xFFFF7F7F),
            Color(0xFFF9D86D),
            Color(0xFFA3D9A5),
            Color(0xFFA3CFFF),
            Color(0xFFC4A3FF),
          ],
          backgroundColor: Colors.white,
          rankColor: Color(0xFF4F46E5),
          scoreColor: Color(0xFF1A1A1A),
          iconColor: Color(0xFF4F46E5),
          glowColor: Color(0xFFC4A3FF),
        ),
      SeasonTier.challenger => const _RankFrameStyle(
          borderColors: [
            Color(0xFFFFD166),
            Color(0xFFFB7185),
            Color(0xFFA855F7),
            Color(0xFF38BDF8),
          ],
          backgroundColor: Color(0xFFFFFBEB),
          rankColor: Color(0xFFA855F7),
          scoreColor: Color(0xFF7C2D12),
          iconColor: Color(0xFFF59E0B),
          glowColor: Color(0xFFF59E0B),
        ),
      SeasonTier.master => const _RankFrameStyle(
          borderColors: [
            Color(0xFFEF4444),
            Color(0xFFF97316),
            Color(0xFFFACC15),
          ],
          backgroundColor: Color(0xFFFFF7ED),
          rankColor: Color(0xFFDC2626),
          scoreColor: Color(0xFF7F1D1D),
          iconColor: Color(0xFFF97316),
          glowColor: Color(0xFFEF4444),
        ),
      SeasonTier.diamond => const _RankFrameStyle(
          borderColors: [
            Color(0xFF67E8F9),
            Color(0xFF38BDF8),
            Color(0xFF2563EB),
          ],
          backgroundColor: Color(0xFFF0F9FF),
          rankColor: Color(0xFF0284C7),
          scoreColor: Color(0xFF075985),
          iconColor: Color(0xFF38BDF8),
          glowColor: Color(0xFF38BDF8),
        ),
      _ => null,
    };
  }
}
