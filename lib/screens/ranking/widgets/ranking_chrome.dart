import 'package:flutter/material.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/theme/app_colors.dart';

import '../ranking_period.dart';

class RankingSheetHandle extends StatelessWidget {
  const RankingSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 48,
          height: 6,
          decoration: BoxDecoration(
            color: charcoalBlack.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class RankingHeader extends StatelessWidget {
  const RankingHeader({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    this.isDailyOnly = false,
    this.dailyDateKey,
  });

  final RankingPeriod period;
  final ValueChanged<RankingPeriod> onPeriodChanged;
  final bool isDailyOnly;
  final String? dailyDateKey;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    if (isDailyOnly) {
      // Daily ranking doesn't have period selector, so we can return empty spacing
      return const SizedBox(height: 8);
    }

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: isLandscape ? 16 : 24),
          height: isLandscape ? 38 : 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.hairline,
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: RankingPeriod.values
                  .where((period) => period != RankingPeriod.daily)
                  .map<Widget>(
                (candidate) {
                  final isActive = candidate == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onPeriodChanged(candidate),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          candidate.tabLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w900 : FontWeight.w700,
                            color: isActive
                                ? AppColors.onPrimary
                                : AppColors.ink.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }

}

class TopPlayersLabel extends StatelessWidget {
  const TopPlayersLabel({
    super.key,
    required this.period,
  });

  final RankingPeriod period;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          period.topPlayersLabel,
          style: AppTypography.label.copyWith(
            fontSize: 11,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w900,
            color: charcoalBlack.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: charcoalBlack.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
