part of 'daily_ranking_calendar_page.dart';

class _DailyPlayButton extends StatefulWidget {
  const _DailyPlayButton({
    required this.onPressed,
    required this.isLoading,
  });

  final Future<void> Function() onPressed;
  final bool isLoading;

  @override
  State<_DailyPlayButton> createState() => _DailyPlayButtonState();
}

class _DailyPlayButtonState extends State<_DailyPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = MediaQuery.sizeOf(context);
    final isLandscape = ms.width > ms.height;
    final btnH = isLandscape
        ? (ms.height * 0.1).clamp(44.0, 64.0)
        : (ms.height * 0.078).clamp(52.0, 72.0);
    final btnFs = isLandscape
        ? (ms.width * 0.025).clamp(16.0, 24.0)
        : (ms.width * 0.06).clamp(18.0, 26.0);
    final br = (ms.width * 0.04).clamp(16.0, 26.0);

    return Container(
      width: double.infinity,
      height: btnH,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(br),
        boxShadow: AppShadows.buttonShadow,
      ),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          return ElevatedButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    widget.onPressed();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(br),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: btnFs * 0.8,
                    height: btnFs * 0.8,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.isLoading ? '입장 중...'.tr : '오늘의 퍼즐'.tr,
                  style: GoogleFonts.blackHanSans(
                    fontSize: btnFs,
                    letterSpacing: 0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DailyTestButton extends StatelessWidget {
  const _DailyTestButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () {
              onPressed();
            },
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: charcoalBlack,
              ),
            )
          : const Icon(Icons.science_rounded),
      label: Text(isLoading ? '테스트 준비 중'.tr : '테스트 플레이'.tr),
      style: OutlinedButton.styleFrom(
        foregroundColor: charcoalBlack,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final headerFs = (sw * 0.055).clamp(17.0, 26.0);
    final subFs = (sw * 0.035).clamp(11.0, 16.0);
    final today = KstClock.nowInKst();
    final monthLabel =
        '${today.year}.${today.month.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFF59E0B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          '오늘의 퍼즐'.tr,
          style: GoogleFonts.blackHanSans(
            fontSize: headerFs,
            color: charcoalBlack,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          monthLabel,
          style: GoogleFonts.notoSans(
            fontSize: subFs,
            fontWeight: FontWeight.w800,
            color: charcoalBlack.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({
    required this.cells,
    required this.selectableDateKeys,
    required this.selectedDateKey,
    required this.myDailyRanks,
    required this.isRankLoading,
    required this.onDateSelected,
  });

  final List<_CalendarCellData> cells;
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
          color: charcoalBlack.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: charcoalBlack.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
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
            color: isSelected ? charcoalBlack : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: charcoalBlack.withValues(alpha: 0.15),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ]
              : null,
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

class _InlineDailyRankingPanel extends StatelessWidget {
  const _InlineDailyRankingPanel({
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
                  color: charcoalBlack.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(dateKey)} ${'랭킹'.tr}',
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
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: charcoalBlack,
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
                  color: charcoalBlack.withValues(alpha: 0.28),
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

class _CalendarCellData {
  const _CalendarCellData({
    required this.dateKey,
    required this.day,
  });

  const _CalendarCellData.empty()
      : dateKey = null,
        day = 0;

  final String? dateKey;
  final int day;
}
