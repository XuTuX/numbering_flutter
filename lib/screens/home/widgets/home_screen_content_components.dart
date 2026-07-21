part of 'home_screen_content.dart';

// ─── 탭 / 인디케이터 ──────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── 오늘의 퍼즐 히어로 영역 ────────────────────────────────────

class _DailyPuzzleHero extends StatelessWidget {
  const _DailyPuzzleHero({
    required this.onStartDaily,
    required this.onShowRanking,
  });

  final VoidCallback onStartDaily;
  final VoidCallback onShowRanking;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onShowRanking,
                icon: const Icon(Icons.leaderboard_rounded, color: AppColors.textPrimary, size: 20),
                label: const Text(
                  '오늘의 랭킹 보기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '오늘의 퍼즐',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: onStartDaily,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '플레이 하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelPackPage extends StatefulWidget {
  const _LevelPackPage({required this.onStartGame});
  final VoidCallback onStartGame;

  @override
  State<_LevelPackPage> createState() => _LevelPackPageState();
}

class _LevelPackPageState extends State<_LevelPackPage> {
  late int _selected;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final cur = Get.find<LevelProgressService>().highestUnlockedLevel;
    _selected = 0;
    for (int i = 0; i < levelPacks.length; i++) {
      if (cur >= levelPacks[i].startLevel && cur <= levelPacks[i].endLevel) {
        _selected = i;
        break;
      }
    }
    _pageController = PageController(viewportFraction: 0.55, initialPage: _selected);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = Get.find<LevelProgressService>();
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final sw = mediaSize.width;
    final hPad = (sw * 0.06).clamp(24.0, 40.0);

    return Obx(() {
      final current = progress.highestUnlockedLevel;
      final records = Map<int, LevelProgress>.of(progress.progress);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isLandscape ? hPad : 0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLandscape ? sw * 0.95 : 480.0),
            child: Column(
              children: [
                // ── 가운데 팩 카드 (Carousel) ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selected = index;
                      });
                    },
                    itemCount: levelPacks.length,
                    itemBuilder: (context, i) {
                      final pack = levelPacks[i];
                      final unlocked = current >= pack.startLevel;
                      final isActive = i == _selected;

                      int cleared = 0;
                      for (int lv = pack.startLevel; lv <= pack.endLevel; lv++) {
                        if (records[lv]?.cleared ?? false) cleared++;
                      }

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - i;
                            value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                          } else {
                            value = isActive ? 1.0 : 0.85;
                          }

                          return Center(
                            child: AspectRatio(
                              aspectRatio: 0.72, // 트렌디한 세로형 뷰 (포스터/타로카드 비율)
                              child: Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: (value - 0.85) / 0.15 * 0.5 + 0.5,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        child: _PackCard(
                          pack: pack,
                          unlocked: unlocked,
                          isActive: isActive,
                          clearedCount: cleared,
                          onTap: unlocked ? () {
                            if (!isActive) {
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Get.to(() => LevelListScreen(
                                    pack: pack,
                                  ));
                            }
                          } : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // ── 이어서 하기 ──
                _ContinueBar(currentLevel: current, onPressed: widget.onStartGame),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── 팩 카드 (Carousel 형태) ──────────────────────────────────────

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.unlocked,
    required this.isActive,
    required this.clearedCount,
    this.onTap,
  });

  final LevelPack pack;
  final bool unlocked;
  final bool isActive;
  final int clearedCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : unlocked
                    ? AppColors.borderLight
                    : const Color(0xFFF0F1F3),
            width: isActive ? 0 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (!unlocked)
              const Positioned(
                top: 20, right: 20,
                child: Icon(Icons.lock_rounded, size: 22, color: Color(0xFFC0C4CA)),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // 중앙 텍스트 (팩 이름)
                  Text(
                    pack.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isActive ? Colors.white : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  // 하단 진행률 영역
                  if (unlocked) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROGRESS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: isActive ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$clearedCount / ${pack.totalLevels}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: clearedCount / pack.totalLevels,
                        minHeight: 6,
                        backgroundColor: isActive
                            ? Colors.black.withValues(alpha: 0.15)
                            : const Color(0xFFE8EAEE),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isActive ? Colors.white : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 이어서 하기 ────────────────────────────────────────────────

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.currentLevel, required this.onPressed});
  final int currentLevel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0095FF),
          borderRadius: BorderRadius.circular(100), // 더 둥근 캡슐 형태
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0095FF).withValues(alpha: 0.3),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, color: Color(0xFF0095FF), size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('이어서 하기',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, height: 1.0),
                ),
                const SizedBox(height: 4),
                Text('LEVEL $currentLevel',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── 홈 헤더 ──────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.authService, required this.onSettingsTap});
  final AuthService authService;
  final VoidCallback onSettingsTap;

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
                      decoration: const BoxDecoration(color: Color(0xFF0095FF), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        hasNickname ? nickname : 'NUMBERING',
                        style: TextStyle(fontSize: titleFs, fontWeight: FontWeight.bold, color: charcoalBlack, height: 1.0),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasNickname) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.edit_rounded, size: 14, color: charcoalBlack.withValues(alpha: 0.2)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            TopIconButton(icon: Icons.settings_rounded, onTap: onSettingsTap),
          ],
        ),
      );
    });
  }
}
