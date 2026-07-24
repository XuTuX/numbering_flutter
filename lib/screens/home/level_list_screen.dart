import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';
import 'package:numbering/screens/home/home_screen_flows.dart';
import 'package:numbering/theme/app_colors.dart';

class LevelListScreen extends StatelessWidget {
  const LevelListScreen({
    super.key,
    required this.pack,
  });

  final LevelPack pack;

  Color _getPackColor(String name) {
    switch (name.toLowerCase()) {
      case 'seoul':
        return AppColors.blockLilac;
      case 'tokyo':
        return AppColors.blockLime;
      case 'new york':
        return AppColors.blockCream;
      case 'sydney':
        return AppColors.blockPink;
      case 'london':
        return AppColors.blockMint;
      case 'paris':
        return AppColors.blockPink;
      default:
        return AppColors.blockLime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = Get.find<LevelProgressService>();
    final mediaSize = MediaQuery.sizeOf(context);
    final hPad = (mediaSize.width * 0.06).clamp(24.0, 40.0);
    final topPad = mediaSize.width > mediaSize.height ? 20.0 : 24.0;
    final packColor = _getPackColor(pack.name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad - 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.ink),
                      onPressed: () => Get.back(),
                      splashRadius: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pack.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Obx(() {
                    final current = progress.highestUnlockedLevel;
                    final records =
                        Map<int, LevelProgress>.of(progress.progress);
                    return LevelGrid(
                      pack: pack,
                      currentLevel: current,
                      records: records,
                      packColor: packColor,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelGrid extends StatelessWidget {
  const LevelGrid({
    super.key,
    required this.pack,
    required this.currentLevel,
    required this.records,
    required this.packColor,
  });

  final LevelPack pack;
  final int currentLevel;
  final Map<int, LevelProgress> records;
  final Color packColor;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: pack.totalLevels,
      itemBuilder: (context, index) {
        final levelId = pack.startLevel + index;
        final unlocked = levelId <= currentLevel;
        final isCurrent = levelId == currentLevel;
        final record = records[levelId];
        final cleared = record?.cleared ?? false;
        final stars = record?.stars ?? 0;

        return LevelTile(
          levelId: levelId,
          unlocked: unlocked,
          isCurrent: isCurrent,
          cleared: cleared,
          stars: stars,
          packColor: packColor,
          onTap: (unlocked || cleared)
              ? () {
                  openGameScreen(
                    GameSessionConfig(
                      mode: GameMode.normal,
                      startLevelId: levelId,
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}

class LevelTile extends StatelessWidget {
  const LevelTile({
    super.key,
    required this.levelId,
    required this.unlocked,
    required this.isCurrent,
    required this.cleared,
    required this.stars,
    required this.packColor,
    this.onTap,
  });

  final int levelId;
  final bool unlocked;
  final bool isCurrent;
  final bool cleared;
  final int stars;
  final Color packColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surfaceSoft;
    Color borderColor = Colors.transparent;
    Color textColor = AppColors.ink.withValues(alpha: 0.3);

    if (isCurrent) {
      bgColor = packColor;
      textColor = AppColors.ink;
    } else if (cleared) {
      bgColor = AppColors.canvas;
      borderColor = AppColors.hairline;
      textColor = AppColors.ink;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              Icon(Icons.lock_rounded,
                  size: 18, color: AppColors.ink.withValues(alpha: 0.15))
            else ...[
              Text(
                '$levelId',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  height: 1.0,
                ),
              ),
              if (cleared) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final lit = i < stars;
                    return Icon(
                      lit ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 10,
                      color: lit
                          ? AppColors.ink
                          : AppColors.ink.withValues(alpha: 0.15),
                    );
                  }),
                ),
              ] else if (isCurrent) ...[
                const SizedBox(height: 4),
                Text(
                  'PLAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink.withValues(alpha: 0.6),
                    letterSpacing: 1.0,
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
