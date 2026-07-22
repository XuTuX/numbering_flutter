import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/services/database_models.dart';

class WeeklyRankingPreview extends StatefulWidget {
  const WeeklyRankingPreview({
    super.key,
    required this.onViewAll,
    this.isAllTime = false,
    this.limit = 5,
  });

  final VoidCallback onViewAll;
  final bool isAllTime;
  final int limit;

  @override
  State<WeeklyRankingPreview> createState() => _WeeklyRankingPreviewState();
}

class _WeeklyRankingPreviewState extends State<WeeklyRankingPreview> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _topScores = [];

  @override
  void initState() {
    super.initState();
    _loadTopScores();
  }

  Future<void> _loadTopScores() async {
    if (!mounted) return;
    setState(() {
      _topScores = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ms = MediaQuery.sizeOf(context);
    final isTablet = ms.shortestSide >= 600;
    final isLandscape = ms.width > ms.height;
    final sw = ms.width;
    final containerPad = isLandscape
        ? 20.0
        : isTablet
            ? (sw * 0.03).clamp(16.0, 24.0)
            : (sw * 0.045).clamp(14.0, 22.0);
    final headerFs = isTablet
        ? (sw * 0.02).clamp(14.0, 18.0)
        : (sw * 0.042).clamp(13.0, 17.0);
    final viewAllFs = isTablet
        ? (sw * 0.014).clamp(10.0, 13.0)
        : (sw * 0.028).clamp(9.0, 12.0);
    final headerGap = isLandscape
        ? 16.0
        : isTablet
            ? 24.0
            : (ms.height * 0.026).clamp(20.0, 24.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final content = _buildRankingContent();

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: containerPad,
            vertical: isLandscape ? 8 : containerPad,
          ),
          child: Column(
            mainAxisSize:
                hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: widget.onViewAll,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      widget.isAllTime ? '전체 랭킹'.tr : '주간 랭킹'.tr,
                      style: GoogleFonts.blackHanSans(
                        fontSize: headerFs,
                        color: charcoalBlack,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '전체 보기'.tr,
                      style: GoogleFonts.notoSans(
                        fontSize: viewAllFs,
                        fontWeight: FontWeight.w700,
                        color: charcoalBlack.withValues(alpha: 0.32),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: viewAllFs + 3,
                      color: charcoalBlack.withValues(alpha: 0.28),
                    ),
                  ],
                ),
              ),
              SizedBox(height: headerGap),
              if (hasBoundedHeight) Expanded(child: content) else content,
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankingContent() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: charcoalBlack.withValues(alpha: 0.2),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_topScores.isEmpty) {
      return Center(
        child: Text(
          '아직 기록이 없습니다'.tr,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: charcoalBlack.withValues(alpha: 0.2),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: List.generate(_topScores.length, (index) {
          return CleanRankRow(
            rank: index + 1,
            data: _topScores[index],
            isLast: index == _topScores.length - 1,
          );
        }),
      ),
    );
  }
}

class CleanRankRow extends StatelessWidget {
  const CleanRankRow({
    super.key,
    required this.rank,
    required this.data,
    this.isLast = false,
  });

  final int rank;
  final Map<String, dynamic> data;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ms = MediaQuery.sizeOf(context);
    final isTablet = ms.shortestSide >= 600;
    final sw = ms.width;
    final sh = ms.height;
    final rankFs = isTablet
        ? (sw * 0.02).clamp(14.0, 18.0)
        : (sw * 0.042).clamp(12.0, 17.0);
    final nameFs = isTablet
        ? (sw * 0.018).clamp(12.0, 16.0)
        : (sw * 0.036).clamp(11.0, 15.0);
    final scoreFs = isTablet
        ? (sw * 0.019).clamp(13.0, 17.0)
        : (sw * 0.039).clamp(12.0, 16.0);
    final rowGap = isTablet
        ? (sh * 0.012).clamp(8.0, 14.0)
        : (sh * 0.012).clamp(6.0, 12.0);

    final profileData = data['profiles'];
    Map<String, dynamic> profiles = {};
    if (profileData is Map<String, dynamic>) {
      profiles = profileData;
    } else if (profileData is List && profileData.isNotEmpty) {
      profiles = profileData[0] as Map<String, dynamic>;
    }

    final nickname = profiles['nickname'] ?? 'Player';
    final score = data['score'] ?? 0;
    final scoreInt = score is int ? score : int.tryParse(score.toString()) ?? 0;
    final tier = SeasonTier.fromScore(scoreInt);
    final frameStyle = _PreviewFrameStyle.forTier(tier);

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFFB7185), // Coral Red
      2 => const Color(0xFFFB923C), // Orange
      3 => const Color(0xFFFBBF24), // Amber Yellow
      _ => charcoalBlack.withValues(alpha: 0.2),
    };

    final rowContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: frameStyle != null
          ? BoxDecoration(
              color: frameStyle.backgroundColor,
              borderRadius: BorderRadius.circular(9),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: rankFs + 8,
            child: Text(
              '$rank',
              style: GoogleFonts.blackHanSans(
                fontSize: rankFs,
                color: frameStyle?.rankColor ?? rankColor,
              ),
            ),
          ),
          SizedBox(width: (sw * 0.025).clamp(6.0, 12.0)),
          Expanded(
            child: Text(
              nickname.toString(),
              style: GoogleFonts.notoSans(
                fontSize: nameFs,
                fontWeight: FontWeight.w700,
                color: frameStyle != null
                    ? charcoalBlack.withValues(alpha: 0.85)
                    : charcoalBlack.withValues(alpha: 0.65),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatScore(score),
            style: GoogleFonts.blackHanSans(
              fontSize: scoreFs,
              color: frameStyle?.scoreColor ??
                  charcoalBlack.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );

    Widget row;
    if (frameStyle != null) {
      row = Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: frameStyle.borderColor,
          borderRadius: BorderRadius.circular(11),
        ),
        child: rowContent,
      );
    } else {
      row = rowContent;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : rowGap),
      child: row,
    );
  }

  String _formatScore(dynamic score) {
    final value = score is int ? score : int.tryParse(score.toString()) ?? 0;
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
}

class _PreviewFrameStyle {
  const _PreviewFrameStyle({
    required this.borderColor,
    required this.backgroundColor,
    required this.rankColor,
    required this.scoreColor,
    required this.iconColor,
  });

  final Color borderColor;
  final Color backgroundColor;
  final Color rankColor;
  final Color scoreColor;
  final Color iconColor;

  static _PreviewFrameStyle? forTier(SeasonTier tier) {
    return switch (tier) {
      SeasonTier.jesus => const _PreviewFrameStyle(
          borderColor: Color(0xFF4F46E5),
          backgroundColor: Colors.white,
          rankColor: Color(0xFF4F46E5),
          scoreColor: Color(0xFF1A1A1A),
          iconColor: Color(0xFF4F46E5),
        ),
      SeasonTier.challenger => const _PreviewFrameStyle(
          borderColor: Color(0xFFA855F7),
          backgroundColor: Color(0xFFFFFBEB),
          rankColor: Color(0xFFA855F7),
          scoreColor: Color(0xFF7C2D12),
          iconColor: Color(0xFFF59E0B),
        ),
      SeasonTier.master => const _PreviewFrameStyle(
          borderColor: Color(0xFFDC2626),
          backgroundColor: Color(0xFFFFF7ED),
          rankColor: Color(0xFFDC2626),
          scoreColor: Color(0xFF7F1D1D),
          iconColor: Color(0xFFF97316),
        ),
      SeasonTier.diamond => const _PreviewFrameStyle(
          borderColor: Color(0xFF0284C7),
          backgroundColor: Color(0xFFF0F9FF),
          rankColor: Color(0xFF0284C7),
          scoreColor: Color(0xFF075985),
          iconColor: Color(0xFF38BDF8),
        ),
      _ => null,
    };
  }
}
