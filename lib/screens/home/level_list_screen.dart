import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';
import 'package:numbering/screens/home/level_list/level_grid.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';

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
      case 'singapore':
        return AppColors.blockMint;
      case 'berlin':
        return AppColors.blockCream;
      case 'cairo':
        return AppColors.blockCoral;
      case 'rio':
        return AppColors.blockPink;
      default:
        return AppColors.blockLime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = Get.find<LevelProgressService>();
    final packColor = _getPackColor(pack.name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                (constraints.maxWidth * 0.045).clamp(20.0, 36.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    24,
                  ),
                  child: Obx(() {
                    final current = progress.highestUnlockedLevel;
                    final records =
                        Map<int, LevelProgress>.of(progress.progress);
                    final clearedCount = pack.levelIds
                        .where((levelId) => records[levelId]?.cleared ?? false)
                        .length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PackHeader(
                          pack: pack,
                          clearedCount: clearedCount,
                          packColor: packColor,
                          onBack: Get.back,
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: LevelGrid(
                            pack: pack,
                            currentLevel: current,
                            records: records,
                            packColor: packColor,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension on LevelPack {
  Iterable<int> get levelIds sync* {
    for (var levelId = startLevel; levelId <= endLevel; levelId++) {
      yield levelId;
    }
  }
}

class _PackHeader extends StatelessWidget {
  const _PackHeader({
    required this.pack,
    required this.clearedCount,
    required this.packColor,
    required this.onBack,
  });

  final LevelPack pack;
  final int clearedCount;
  final Color packColor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress = clearedCount / pack.totalLevels;
    final progressWidth =
        (MediaQuery.sizeOf(context).width * 0.24).clamp(84.0, 156.0);

    return Row(
      children: [
        IconButton(
          key: const ValueKey('level-list-back-button'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.ink,
          iconSize: 22,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pack.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: 0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: progressWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$clearedCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const Text(
                    ' / ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.7,
                    ),
                  ),
                  Text(
                    '${pack.totalLevels}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  key: const ValueKey('level-pack-progress'),
                  value: progress,
                  minHeight: 7,
                  backgroundColor: packColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
