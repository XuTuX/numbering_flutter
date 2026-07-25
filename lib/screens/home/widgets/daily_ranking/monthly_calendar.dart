import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/utils/kst_clock.dart';

const charcoalBlack = Color(0xFF17191D);

class MonthlyCalendar extends StatelessWidget {
  const MonthlyCalendar({
    super.key,
    required this.cells,
    required this.selectableDateKeys,
    required this.selectedDateKey,
    required this.myDailyRanks,
    required this.isRankLoading,
    required this.onDateSelected,
  });

  final List<CalendarCellData> cells;
  final Set<String> selectableDateKeys;
  final String selectedDateKey;
  final Map<String, int> myDailyRanks;
  final bool isRankLoading;
  final ValueChanged<String> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final todayKey = KstClock.currentDateKey();
    const columns = 7;
    const gap = 4.0;
    final sh = MediaQuery.sizeOf(context).height;
    // Proportional cell height
    final cellH = (sh * 0.055).clamp(36.0, 56.0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chipWidth =
              (constraints.maxWidth - (gap * (columns - 1))) / columns;
          return Column(
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cells.map((cell) {
                  final dateKey = cell.dateKey;
                  if (dateKey == null) {
                    return SizedBox(width: chipWidth, height: cellH);
                  }

                  final isEnabled = selectableDateKeys.contains(dateKey);
                  return _DateChip(
                    width: chipWidth,
                    height: cellH,
                    day: cell.day,
                    rank: myDailyRanks[dateKey],
                    isSelected: dateKey == selectedDateKey,
                    isToday: dateKey == todayKey,
                    isEnabled: isEnabled,
                    isRankLoading: isRankLoading,
                    onTap: isEnabled ? () => onDateSelected(dateKey) : null,
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.width,
    required this.height,
    required this.day,
    required this.rank,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.isRankLoading,
    required this.onTap,
  });

  final double width;
  final double height;
  final int day;
  final int? rank;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final bool isRankLoading;
  final VoidCallback? onTap;

  /// Subtle dot color based on rank tier — no text, just a small indicator.
  Color get _rankBackgroundColor {
    if (rank == null) return Colors.transparent;
    return switch (rank!) {
      1 => const Color(0xFFFB7185), // Coral Red (1st)
      2 => const Color(0xFFFB923C), // Orange (2nd)
      3 => const Color(0xFFFBBF24), // Amber Yellow (3rd)
      _ => const Color(0xFFE2E8F0), // Participation (Subtle Slate)
    };
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        (rank != null) ? _rankBackgroundColor : const Color(0xFFF8FAFC);
    final foregroundColor =
        isEnabled ? charcoalBlack : charcoalBlack.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? charcoalBlack : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: GoogleFonts.blackHanSans(
                fontSize: 13,
                color: foregroundColor,
                height: 1.0,
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: charcoalBlack.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ] else if (isRankLoading && isEnabled) ...[
              const SizedBox(height: 3),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: charcoalBlack.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CalendarCellData {
  const CalendarCellData({
    required this.dateKey,
    required this.day,
  });

  const CalendarCellData.empty()
      : dateKey = null,
        day = 0;

  final String? dateKey;
  final int day;
}
