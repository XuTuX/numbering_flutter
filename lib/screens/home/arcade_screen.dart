import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/screens/home/level_list_screen.dart';
import 'widgets/home_screen_content.dart' show LevelPack, levelPacks;

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key, required this.onStartGame});
  final VoidCallback onStartGame;

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text('Arcade', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Removed GridPatternPainter for clean Figma aesthetic
          Obx(() {
            final current = progress.highestUnlockedLevel;
            final records = Map<int, LevelProgress>.of(progress.progress);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: isLandscape ? hPad : 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isLandscape ? sw * 0.95 : 480.0),
                  child: Column(
                    children: [
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

                            final isLandscape = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
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
                                    aspectRatio: isLandscape ? 1.05 : 0.72,
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
                      _ContinueBar(currentLevel: current, onPressed: widget.onStartGame),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

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
    Color getBlockColor(String name) {
      if (!unlocked) return AppColors.surfaceSoft;
      if (!isActive) return AppColors.canvas;
      switch (name.toLowerCase()) {
        case 'seoul': return AppColors.blockLilac;
        case 'tokyo': return AppColors.blockLime;
        case 'new york': return AppColors.blockCream;
        case 'london': return AppColors.blockMint;
        case 'paris': return AppColors.blockPink;
        default: return AppColors.blockLime;
      }
    }

    final cardColor = getBlockColor(pack.name);
    final isColorBlock = isActive && unlocked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: isColorBlock ? null : Border.all(color: AppColors.borderLight, width: 1.0),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pack.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isColorBlock ? AppColors.ink : (unlocked ? AppColors.ink : AppColors.textSecondary),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 3),
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
                            color: isColorBlock ? AppColors.ink.withValues(alpha: 0.6) : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$clearedCount / ${pack.totalLevels}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: clearedCount / pack.totalLevels,
                        minHeight: 8,
                        backgroundColor: isColorBlock
                            ? AppColors.canvas.withValues(alpha: 0.6)
                            : AppColors.surfaceSoft,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
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

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.currentLevel, required this.onPressed});
  final int currentLevel;
  final VoidCallback onPressed;

  String _getPackName(int level) {
    for (var p in levelPacks) {
      if (level >= p.startLevel && level <= p.endLevel) return p.name.toUpperCase();
    }
    return 'SEOUL';
  }

  @override
  Widget build(BuildContext context) {
    final packName = _getPackName(currentLevel);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: AppColors.onPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(packName,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onPrimary.withValues(alpha: 0.7), height: 1.0, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text('LEVEL $currentLevel',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.onPrimary, height: 1.0, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Icon(Icons.chevron_right_rounded, color: AppColors.onPrimary.withValues(alpha: 0.7), size: 24),
          ],
        ),
      ),
    );
  }
}
