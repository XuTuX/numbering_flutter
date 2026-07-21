import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';
import 'package:numbering/screens/home/home_screen_flows.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/widgets/home_screen/components/home_branding.dart';

class LevelListScreen extends StatelessWidget {
  const LevelListScreen({
    super.key,
    required this.pack,
  });

  final LevelPack pack;

  @override
  Widget build(BuildContext context) {
    final progress = Get.find<LevelProgressService>();
    final mediaSize = MediaQuery.sizeOf(context);
    final hPad = (mediaSize.width * 0.06).clamp(24.0, 40.0);
    final topPad = mediaSize.width > mediaSize.height ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  children: [
                    TopIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Get.back(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      pack.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Obx(() {
                    final current = progress.highestUnlockedLevel;
                    final records = Map<int, LevelProgress>.of(progress.progress);
                    return LevelGrid(
                      pack: pack,
                      currentLevel: current,
                      records: records,
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
  });

  final LevelPack pack;
  final int currentLevel;
  final Map<int, LevelProgress> records;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
