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
  });

  final String dateLabel;
  final Future<void> Function() onTap;

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
                const Spacer(),
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
  const _RankingCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      color: _rankingSurface,
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR RANK',
              style: TextStyle(
                color: Color(0x8F171716),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '#24',
                style: TextStyle(
                  color: _homeInk,
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            Spacer(),
            Align(
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
    required this.onSettingsTap,
    required this.onProfileTap,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NUMBERING',
                style: TextStyle(
                  color: _homeInk,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          _HeaderIconButton(
            tooltip: 'Profile',
            icon: Icons.person_outline_rounded,
            onTap: onProfileTap,
          ),
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
