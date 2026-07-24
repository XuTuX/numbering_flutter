part of 'home_screen_content.dart';

const _homeInk = AppColors.ink;
const _homeBackground = AppColors.background;
const _challengeSurface = AppColors.surfaceSoft;
const _arcadeSurface = AppColors.blockLilac;
const _rankingSurface = AppColors.blockMint;
const _homeBorder = AppColors.hairline;

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.dateLabel,
    required this.onTap,
    required this.state,
    this.score,
  });

  final String dateLabel;
  final Future<void> Function() onTap;
  final DailyChallengeUiState state;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      color: _challengeSurface,
      onTap: () async => onTap(),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            bottom: -26,
            child: ExcludeSemantics(
              child: Text(
                dateLabel,
                key: const ValueKey('challenge-date'),
                style: const TextStyle(
                  color: Color(0x0C171716),
                  fontSize: 132,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -8,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's\nChallenge",
                  style: TextStyle(
                    color: _homeInk,
                    fontSize: 36,
                    height: 0.98,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.6,
                  ),
                ),
                if (state != DailyChallengeUiState.available) ...[
                  Text(
                    switch (state) {
                      DailyChallengeUiState.loading => '불러오는 중…',
                      DailyChallengeUiState.alreadyPlayed =>
                        '완료 · ${score ?? 0}점',
                      DailyChallengeUiState.notAuthenticated => '로그인 후 도전',
                      DailyChallengeUiState.networkError => '연결 오류 · 다시 시도',
                      DailyChallengeUiState.submissionError => '제출 오류 · 다시 시도',
                      DailyChallengeUiState.available => '',
                    },
                    style: const TextStyle(
                      color: Color(0x8F171716),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const Align(
                  alignment: Alignment.bottomRight,
                  child: _ArrowCircle(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeCard extends StatelessWidget {
  const _ArcadeCard({
    required this.roundLabel,
    required this.onTap,
  });

  final String roundLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      color: _arcadeSurface,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Positioned(
              left: -6,
              right: -6,
              bottom: -8,
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    roundLabel,
                    key: const ValueKey('arcade-round-background'),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0x0A171716),
                      fontSize: 58,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -3,
                    ),
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.topLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Arcade',
                  style: TextStyle(
                    color: _homeInk,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: _ArrowCircle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.onTap,
    required this.rank,
    required this.bestScore,
  });

  final VoidCallback onTap;
  final int? rank;
  final int? bestScore;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      color: _rankingSurface,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR RANK',
              style: TextStyle(
                color: Color(0x8F171716),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                rank == null ? '#—' : '#$rank',
                style: const TextStyle(
                  color: _homeInk,
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            if (bestScore != null)
              Text(
                'BEST $bestScore',
                style: const TextStyle(
                  color: Color(0x8F171716),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const Spacer(),
            const Align(
              alignment: Alignment.bottomRight,
              child: _ArrowCircle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowCircle extends StatelessWidget {
  const _ArrowCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xDFFFFFFF),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: _homeInk,
        size: 17,
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.color,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: _homeBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: _homeInk.withValues(alpha: 0.04),
        highlightColor: _homeInk.withValues(alpha: 0.025),
        child: child,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.nickname,
    required this.onNicknameTap,
    required this.onSettingsTap,
  });

  final String? nickname;
  final VoidCallback? onNicknameTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _HomeIdentity(
                nickname: nickname,
                onNicknameTap: onNicknameTap,
              ),
            ),
          ),
          const _HomeHeaderHintBadge(),
          const SizedBox(width: 10),
          _HeaderIconButton(
            tooltip: 'Settings',
            icon: Icons.tune_rounded,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _HomeHeaderHintBadge extends StatelessWidget {
  const _HomeHeaderHintBadge();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HintService>()) {
      return const _HintBadge(hints: 20);
    }
    final hintService = Get.find<HintService>();
    return Obx(
      () => _HintBadge(
        hints: hintService.hints.value,
        onTap: Get.isRegistered<HintPurchaseService>()
            ? () => Get.to(() => const HintStoreScreen())
            : null,
      ),
    );
  }
}

class _HintBadge extends StatelessWidget {
  const _HintBadge({required this.hints, this.onTap});
  final int hints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: onTap == null ? '보유 힌트 (매일 출석 시 +3개)' : '힌트 상점 열기',
      child: Material(
        color: _challengeSurface,
        shape: const StadiumBorder(side: BorderSide(color: _homeBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('home-hint-store'),
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  size: 18,
                  color: Color(0xFFFFB800),
                ),
                const SizedBox(width: 6),
                Text(
                  '$hints',
                  style: const TextStyle(
                    color: _homeInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.add_rounded, size: 15, color: _homeInk),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeIdentity extends StatelessWidget {
  const _HomeIdentity({
    required this.nickname,
    required this.onNicknameTap,
  });

  final String? nickname;
  final VoidCallback? onNicknameTap;

  @override
  Widget build(BuildContext context) {
    final displayName = nickname?.trim();
    final hasNickname = displayName != null && displayName.isNotEmpty;
    final label = hasNickname ? displayName : 'NUMBERING';

    const textStyle = TextStyle(
      color: _homeInk,
      fontSize: 22,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
    );

    if (!hasNickname || onNicknameTap == null) {
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return Tooltip(
      message: '닉네임 변경'.tr,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('home-nickname'),
          onTap: onNicknameTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        color: _homeInk,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0x80FFFFFF),
          side: const BorderSide(color: _homeBorder),
        ),
      ),
    );
  }
}
