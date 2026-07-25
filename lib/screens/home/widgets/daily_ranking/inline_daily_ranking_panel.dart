import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_shadows.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/widgets/home_screen/components/weekly_ranking_preview.dart';

class InlineDailyRankingPanel extends StatelessWidget {
  const InlineDailyRankingPanel({
    super.key,
    required this.dateKey,
    required this.scores,
    required this.myId,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onViewAll,
  });

  final String dateKey;
  final List<Map<String, dynamic>> scores;
  final String? myId;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final panelPad = isTablet
        ? (sw * 0.03).clamp(16.0, 24.0)
        : (sw * 0.045).clamp(14.0, 22.0);
    final headerFs = isTablet
        ? (sw * 0.02).clamp(14.0, 18.0)
        : (sw * 0.042).clamp(13.0, 17.0);

    final viewAllFs = isTablet
        ? (sw * 0.014).clamp(10.0, 13.0)
        : (sw * 0.028).clamp(9.0, 12.0);
    final headerGap = isTablet
        ? 16.0
        : (MediaQuery.sizeOf(context).height * 0.016).clamp(10.0, 16.0);

    return Container(
      padding: EdgeInsets.all(panelPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onViewAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: headerFs - 1,
                  color: AppColors.ink.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(dateKey)} ${'랭킹'.tr}',
                  style: GoogleFonts.blackHanSans(
                    fontSize: headerFs,
                    color: AppColors.ink,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Text(
                  '전체 보기'.tr,
                  style: GoogleFonts.notoSans(
                    fontSize: viewAllFs,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink.withValues(alpha: 0.32),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: viewAllFs + 3,
                  color: AppColors.ink.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
          SizedBox(height: headerGap),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.ink,
                    strokeWidth: 3,
                  ),
                ),
              ),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onRetry,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      '다시 불러오기'.tr,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (scores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                '아직 기록이 없습니다'.tr,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink.withValues(alpha: 0.28),
                ),
              ),
            )
          else
            ...List.generate(
              scores.length > 3 ? 3 : scores.length,
              (index) => CleanRankRow(
                rank: index + 1,
                data: scores[index],
                isLast: index == (scores.length > 3 ? 3 : scores.length) - 1,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return dateKey;
    }

    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (month == null || day == null) {
      return dateKey;
    }

    return '$month.$day';
  }
}
