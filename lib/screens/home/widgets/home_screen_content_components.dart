part of 'home_screen_content.dart';

class _Top3RankingCard extends StatelessWidget {
  const _Top3RankingCard({required this.onShowRanking});
  final VoidCallback onShowRanking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onShowRanking,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.blockLilac,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '명예의 전당 (TOP 3)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.ink, size: 24),
              ],
            ),
            const SizedBox(height: 24),
            // Placeholder rows for 1st, 2nd, 3rd
            _buildRankRow(1, '-', '-'),
            const SizedBox(height: 12),
            _buildRankRow(2, '-', '-'),
            const SizedBox(height: 12),
            _buildRankRow(3, '-', '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildRankRow(int rank, String name, String score) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink),
          ),
        ),
        Text(
          score,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
      ],
    );
  }
}


class _CompactArcadeButton extends StatelessWidget {
  const _CompactArcadeButton({
    required this.currentLevel,
    required this.onOpenLevelList,
    required this.onPlayCurrent,
  });
  
  final int currentLevel;
  final VoidCallback onOpenLevelList;
  final VoidCallback onPlayCurrent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenLevelList,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.blockLime,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '아케이드',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onPlayCurrent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.play_arrow_rounded, color: AppColors.onPrimary, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDailyButton extends StatelessWidget {
  const _CompactDailyButton({required this.onTap});
  
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.blockCream,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '오늘의\n퍼즐',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.play_arrow_rounded, color: AppColors.ink, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.authService,
    required this.onSettingsTap,
    required this.onProfileTap,
  });
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final titleFs = (sw * 0.035).clamp(18.0, 24.0);

    return Obx(() {
      final nickname = authService.userNickname.value?.trim();
      final hasNickname = nickname != null && nickname.isNotEmpty;

      return SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: hasNickname
                    ? () => Get.dialog(
                          EditNicknameDialog(
                            currentNickname: nickname,
                            onSave: authService.updateNickname,
                          ),
                          barrierDismissible: false,
                        )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        hasNickname ? nickname : 'NUMBERING',
                        style: TextStyle(fontSize: titleFs, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.0),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasNickname) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.edit_rounded, size: 14, color: AppColors.textPrimary.withValues(alpha: 0.2)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            TopIconButton(icon: Icons.person_rounded, onTap: onProfileTap),
            const SizedBox(width: 8),
            TopIconButton(icon: Icons.settings_rounded, onTap: onSettingsTap),
          ],
        ),
      );
    });
  }
}
