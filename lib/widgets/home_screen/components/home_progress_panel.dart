import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_shadows.dart';
import 'package:numbering/l10n/app_translations.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/database_models.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/utils/kst_clock.dart';

class HomeProgressPanel extends StatefulWidget {
  const HomeProgressPanel({
    super.key,
    required this.authService,
    required this.onStartDaily,
    required this.onShowDailyRanking,
  });

  final AuthService authService;
  final Future<void> Function() onStartDaily;
  final VoidCallback onShowDailyRanking;

  @override
  State<HomeProgressPanel> createState() => _HomeProgressPanelState();
}

class _HomeProgressPanelState extends State<HomeProgressPanel> {
  bool _isLoading = true;
  DailyChallengeInfo? _dailyChallenge;
  int? _dailyRank;
  late final Worker _authWorker;

  @override
  void initState() {
    super.initState();
    _load();
    _authWorker = ever(widget.authService.user, (_) => _load());
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _dailyChallenge = DailyChallengeInfo(
        dateKey: KstClock.currentDateKey(),
        seed: int.tryParse(
              KstClock.currentDateKey().replaceAll('-', ''),
            ) ??
            0,
        hasUsedEntry: false,
      );
      _dailyRank = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TodayPuzzleCard(
      isLoading: _isLoading,
      challenge: _dailyChallenge,
      dailyRank: _dailyRank,
      isLoggedIn: widget.authService.user.value != null,
      onPressed: widget.onStartDaily,
      onShowRanking: widget.onShowDailyRanking,
    );
  }
}

class _TodayPuzzleCard extends StatelessWidget {
  const _TodayPuzzleCard({
    required this.isLoading,
    required this.challenge,
    required this.dailyRank,
    required this.isLoggedIn,
    required this.onPressed,
    required this.onShowRanking,
  });

  final bool isLoading;
  final DailyChallengeInfo? challenge;
  final int? dailyRank;
  final bool isLoggedIn;
  final Future<void> Function() onPressed;
  final VoidCallback onShowRanking;

  @override
  Widget build(BuildContext context) {
    final hasUsedAttempt = challenge?.hasUsedEntry ?? false;
    final hasScoreEntry = challenge?.hasScoreEntry ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                if (hasUsedAttempt && hasScoreEntry) {
                  onShowRanking();
                } else {
                  onPressed();
                }
              },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blockLilac,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.ink,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildContent()),
              const SizedBox(width: 10),
              _ActionPill(
                label: _actionLabel(hasUsedAttempt: hasUsedAttempt),
                isLoading: isLoading,
                isWarning: hasUsedAttempt && challenge?.myScore == null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(),
          const SizedBox(height: 5),
          Text(
            '기록을 불러오는 중'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: charcoalBlack.withValues(alpha: 0.45),
            ),
          ),
        ],
      );
    }

    final hasUsedAttempt = challenge?.hasUsedEntry ?? false;

    if (!isLoggedIn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(),
          const SizedBox(height: 5),
          Text(
            '로그인 후 12시간마다 참여 가능',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: charcoalBlack.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    if (hasUsedAttempt) {
      final scoreText = challenge?.myScore == null
          ? '기록이 누락돼 다시 제출할 수 있어요'.tr
          : dailyRank != null
              ? '${AppTranslations.points(_formatScoreText(challenge!.myScore!))} · ${AppTranslations.rank(dailyRank!)}'
              : AppTranslations.points(_formatScoreText(challenge!.myScore!));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(),
          const SizedBox(height: 5),
          Text(
            scoreText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: challenge?.myScore == null
                  ? const Color(0xFFDC2626)
                  : AppColors.ink,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleText(),
        const SizedBox(height: 5),
        Text(
          '공식 기록이 오늘 랭킹에 반영돼요'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: charcoalBlack.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _titleText() {
    return Text(
      '오늘의 퍼즐'.tr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.blackHanSans(
        fontSize: 17,
        color: charcoalBlack,
        letterSpacing: 0,
      ),
    );
  }

  String _actionLabel({required bool hasUsedAttempt}) {
    if (isLoading) return '';
    if (!isLoggedIn) return '로그인'.tr;
    if (hasUsedAttempt && challenge?.myScore == null) return '재입장'.tr;
    if (hasUsedAttempt) return '랭킹'.tr;
    return '도전'.tr;
  }

  String _formatScoreText(int value) {
    final digits = value.toString();
    if (digits.length <= 3) {
      return digits;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.isLoading,
    required this.isWarning,
  });

  final String label;
  final bool isLoading;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: charcoalBlack,
        ),
      );
    }

    final color = isWarning ? const Color(0xFFB91C1C) : const Color(0xFF0369A1);
    final background =
        isWarning ? const Color(0xFFFEF2F2) : const Color(0xFFE0F2FE);

    return Container(
      constraints: const BoxConstraints(minWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
