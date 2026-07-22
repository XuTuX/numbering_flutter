import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/game/game_palette.dart';
import 'package:numbering/services/database_models.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_shadows.dart';

import '../ranking_period.dart';
import '../weekly_reset_info.dart';

class MyRankCard extends StatelessWidget {
  const MyRankCard({
    super.key,
    this.rank,
    this.score,
    required this.isLoggedIn,
    required this.period,
    this.weeklySeasonSummary,
    this.onLoginTap,
  });

  final int? rank;
  final int? score;
  final bool isLoggedIn;
  final RankingPeriod period;
  final WeeklySeasonSummary? weeklySeasonSummary;
  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    final weeklyResetInfo = WeeklyResetInfo.current();
    if (rank == null || score == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isLoggedIn
                  ? Icons.sentiment_dissatisfied_outlined
                  : Icons.person_outline_rounded,
              color: charcoalBlack.withValues(alpha: 0.18),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              isLoggedIn
                  ? period.loggedInEmptyMessage
                  : '로그인하면 랭킹에 참여할 수 있어요'.tr,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: charcoalBlack.withValues(alpha: 0.4),
              ),
            ),
            if (!isLoggedIn && onLoginTap != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: onLoginTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: charcoalBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    textStyle: AppTypography.button.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text('로그인'.tr),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final accentColor = switch (period) {
      RankingPeriod.daily => const Color(0xFF2563EB),
      RankingPeriod.weekly => GamePalette.colorFor(GameColor.coral),
      RankingPeriod.allTime => GamePalette.colorFor(GameColor.violet),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                period.tabLabel,
                style: AppTypography.label.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: charcoalBlack.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              if (period == RankingPeriod.weekly)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 12, color: charcoalBlack.withValues(alpha: 0.3)),
                    const SizedBox(width: 4),
                    Text(
                      weeklyResetInfo.koreanLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: charcoalBlack.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  period.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: charcoalBlack.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (period == RankingPeriod.weekly &&
              weeklySeasonSummary != null) ...[
            _TierBadge(tier: weeklySeasonSummary!.tier),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$rank',
                style: GoogleFonts.blackHanSans(
                  fontSize: 36,
                  color: accentColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '위'.tr,
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 1,
                height: 22,
                color: charcoalBlack.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 20),
              Text(
                '$score',
                style: GoogleFonts.blackHanSans(
                  fontSize: 36,
                  color: charcoalBlack,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '점'.tr,
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final SeasonTier tier;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          if (tier == SeasonTier.jesus ||
              tier == SeasonTier.challenger ||
              tier == SeasonTier.master ||
              tier == SeasonTier.diamond)
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _tierBackgroundColor(tier),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${tier.label} TIER',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tierColor(SeasonTier tier) {
    return switch (tier) {
      SeasonTier.jesus => const Color(0xFF4F46E5),
      SeasonTier.challenger => const Color(0xFFA855F7),
      SeasonTier.master => const Color(0xFFDC2626),
      SeasonTier.diamond => const Color(0xFF0284C7),
      SeasonTier.platinum => const Color(0xFF64748B),
      SeasonTier.gold => const Color(0xFFF59E0B),
      SeasonTier.silver => const Color(0xFF94A3B8),
      SeasonTier.bronze => const Color(0xFFB45309),
    };
  }

  Color _tierBackgroundColor(SeasonTier tier) {
    return switch (tier) {
      SeasonTier.jesus => Colors.white,
      SeasonTier.challenger => const Color(0xFFFFFBEB),
      SeasonTier.master => const Color(0xFFFFF7ED),
      SeasonTier.diamond => const Color(0xFFF0F9FF),
      SeasonTier.platinum => const Color(0xFFF8FAFC),
      SeasonTier.gold => const Color(0xFFFFFBEB),
      SeasonTier.silver => const Color(0xFFF8FAFC),
      SeasonTier.bronze => const Color(0xFFFFF7ED),
    };
  }

  // Removed _tierBorderColors to eliminate AI gradient look
}
