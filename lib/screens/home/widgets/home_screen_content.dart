import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/widgets/home_screen/background_painter.dart';
import 'package:numbering/widgets/home_screen/home_components.dart';
import 'package:numbering/theme/app_colors.dart';

// ─── 레벨 팩 ────────────────────────────────────────────────────

class _LevelPack {
  const _LevelPack(this.name, this.startLevel, this.endLevel);
  final String name;
  final int startLevel;
  final int endLevel;
  int get totalLevels => endLevel - startLevel + 1;
}

const _packs = [
  _LevelPack('Seoul', 1, 40),
  _LevelPack('Tokyo', 41, 80),
  _LevelPack('New York', 81, 120),
  _LevelPack('London', 121, 160),
  _LevelPack('Paris', 161, 200),
];

// ─── 홈 화면 ────────────────────────────────────────────────────

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({
    super.key,
    required this.scoreController,
    required this.authService,
    required this.onSettingsTap,
    required this.onStartGame,
    required this.onOpenLevelList,
    required this.onStartDaily,
    required this.onStartDailyTest,
    required this.onShowDailyRanking,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final VoidCallback onOpenLevelList;
  final Future<void> Function() onStartDaily;
  final Future<void> Function() onStartDailyTest;
  final ValueChanged<String> onShowDailyRanking;
  final VoidCallback onRankingTap;

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final hPad = (mediaSize.width * 0.06).clamp(24.0, 40.0);
    final topPad = isLandscape ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: GridPatternPainter()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: topPad),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isLandscape ? 820 : 480),
                        child: _HomeHeader(
                          authService: widget.authService,
                          onSettingsTap: widget.onSettingsTap,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _LevelPackPage(onStartGame: widget.onStartGame),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 팩 페이지 ──────────────────────────────────────────────────

class _LevelPackPage extends StatefulWidget {
  const _LevelPackPage({required this.onStartGame});
  final VoidCallback onStartGame;

  @override
  State<_LevelPackPage> createState() => _LevelPackPageState();
}

class _LevelPackPageState extends State<_LevelPackPage> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    final cur = Get.find<LevelProgressService>().highestUnlockedLevel;
    _selected = 0;
    for (int i = 0; i < _packs.length; i++) {
      if (cur >= _packs[i].startLevel && cur <= _packs[i].endLevel) {
        _selected = i;
        break;
      }
    }
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
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLandscape ? sw * 0.95 : 480.0),
            child: Column(
              children: [
                // ── 이어서 하기 ──
                _ContinueBar(currentLevel: current, onPressed: widget.onStartGame),
                const SizedBox(height: 16),
                // ── 가로 팩 카드 ──
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _packs.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) {
                      final pack = _packs[i];
                      final unlocked = current >= pack.startLevel;
                      final isActive = i == _selected;

                      int cleared = 0;
                      for (int lv = pack.startLevel; lv <= pack.endLevel; lv++) {
                        if (records[lv]?.cleared ?? false) cleared++;
                      }

                      return Padding(
                        padding: EdgeInsets.only(right: i < _packs.length - 1 ? 10 : 0),
                        child: _PackCard(
                          pack: pack,
                          unlocked: unlocked,
                          isActive: isActive,
                          clearedCount: cleared,
                          onTap: unlocked ? () => setState(() => _selected = i) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // ── 선택된 팩의 레벨 그리드 ──
                Expanded(
                  child: _LevelGrid(
                    pack: _packs[_selected],
                    currentLevel: current,
                    records: records,
                    onStartGame: widget.onStartGame,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── 팩 카드 (가로 스크롤) ──────────────────────────────────────

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.unlocked,
    required this.isActive,
    required this.clearedCount,
    this.onTap,
  });

  final _LevelPack pack;
  final bool unlocked;
  final bool isActive;
  final int clearedCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0095FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFF0095FF)
                : unlocked
                    ? AppColors.borderLight
                    : const Color(0xFFF0F1F3),
            width: isActive ? 0 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF0095FF).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFC0C4CA))
            else ...[
              Text(
                pack.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // 진행률 바
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: clearedCount / pack.totalLevels,
                  minHeight: 4,
                  backgroundColor: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF0F1F3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isActive ? Colors.white : const Color(0xFF0095FF),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$clearedCount/${pack.totalLevels}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 레벨 그리드 ────────────────────────────────────────────────

class _LevelGrid extends StatelessWidget {
  const _LevelGrid({
    required this.pack,
    required this.currentLevel,
    required this.records,
    required this.onStartGame,
  });

  final _LevelPack pack;
  final int currentLevel;
  final Map<int, LevelProgress> records;
  final VoidCallback onStartGame;

  @override
  Widget build(BuildContext context) {
    final rowCount = (pack.totalLevels / 5).ceil();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: rowCount,
      itemBuilder: (context, row) {
        final start = pack.startLevel + row * 5;
        final remaining = (pack.endLevel - start + 1).clamp(0, 5);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(5, (i) {
              if (i >= remaining) return const Expanded(child: SizedBox());
              final levelId = start + i;
              final unlocked = levelId <= currentLevel;
              final isCurrent = levelId == currentLevel;
              final record = records[levelId];
              final cleared = record?.cleared ?? false;
              final stars = record?.stars ?? 0;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 5 : 0),
                  child: _LevelTile(
                    levelId: levelId,
                    unlocked: unlocked,
                    isCurrent: isCurrent,
                    cleared: cleared,
                    stars: stars,
                    onTap: isCurrent ? onStartGame : null,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ─── 레벨 타일 ──────────────────────────────────────────────────

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.levelId,
    required this.unlocked,
    required this.isCurrent,
    required this.cleared,
    required this.stars,
    this.onTap,
  });

  final int levelId;
  final bool unlocked;
  final bool isCurrent;
  final bool cleared;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF0095FF)
              : cleared
                  ? Colors.white
                  : unlocked
                      ? Colors.white
                      : const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent
                ? const Color(0xFF0095FF)
                : cleared
                    ? const Color(0xFFCEE8D4)
                    : const Color(0xFFE8EAEE),
            width: isCurrent ? 0 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: const Color(0xFF0095FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded, size: 15, color: Color(0xFFC0C4CA))
            else ...[
              Text(
                '$levelId',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? Colors.white : AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              if (cleared) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final lit = i < stars;
                    return Icon(
                      lit ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 9,
                      color: lit ? const Color(0xFFFFB800) : const Color(0xFFDDE0E4),
                    );
                  }),
                ),
              ] else if (isCurrent) ...[
                const SizedBox(height: 1),
                const Text(
                  'PLAY',
                  style: TextStyle(
                    fontSize: 7, fontWeight: FontWeight.w800,
                    color: Colors.white70, letterSpacing: 0.8,
                  ),
                ),
              ],
            ],
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0095FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0095FF).withValues(alpha: 0.2),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이어서 하기',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, height: 1.0),
                  ),
                  const SizedBox(height: 3),
                  Text('LEVEL $currentLevel',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
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
