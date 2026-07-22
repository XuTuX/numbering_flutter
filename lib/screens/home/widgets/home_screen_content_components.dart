part of 'home_screen_content.dart';

class _Top3RankingCard extends StatelessWidget {
  const _Top3RankingCard({required this.onShowRanking});
  final VoidCallback onShowRanking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onShowRanking,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.blockLilac,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '명예의 전당 (TOP 3)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.ink, size: 22),
              ],
            ),
            const SizedBox(height: 16),
            _buildRankRow(1, '-', '-'),
            const SizedBox(height: 8),
            _buildRankRow(2, '-', '-'),
            const SizedBox(height: 8),
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
          width: 26, height: 26,
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink),
          ),
        ),
        Text(
          score,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
      ],
    );
  }
}


class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink, size: 20),
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
