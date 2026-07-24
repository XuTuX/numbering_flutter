import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/screens/home/home_screen_flows.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';
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
                (constraints.maxWidth * 0.045).clamp(24.0, 44.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    10,
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

    return Row(
      children: [
        Material(
          color: AppColors.canvas,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            key: const ValueKey('level-list-back-button'),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.ink,
            iconSize: 22,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
          ),
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
              const SizedBox(height: 6),
              Text(
                '${pack.startLevel.toString().padLeft(2, '0')} — '
                '${pack.endLevel.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.1,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 156,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 5;
        final rowCount = (pack.totalLevels / crossAxisCount).ceil();
        const spacing = 10.0;
        final availableRowHeight =
            (constraints.maxHeight - (rowCount - 1) * spacing) / rowCount;
        final rowHeight = math.max(54.0, availableRowHeight);

        return GridView.builder(
          key: const ValueKey('level-grid'),
          padding: EdgeInsets.zero,
          physics: availableRowHeight >= 54
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: rowHeight,
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
    final backgroundColor = isCurrent
        ? packColor
        : cleared
            ? AppColors.canvas
            : AppColors.surfaceSoft;
    final foregroundColor =
        unlocked ? AppColors.ink : AppColors.ink.withValues(alpha: 0.24);
    final statusLabel = cleared
        ? '$stars stars completed'
        : isCurrent
            ? 'current level'
            : unlocked
                ? 'unlocked'
                : 'locked';

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: 'Level $levelId, $statusLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('level-tile-$levelId'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: cleared ? AppColors.hairline : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelId.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: foregroundColor,
                          letterSpacing: -0.2,
                          height: 1,
                        ),
                      ),
                      if (cleared) ...[
                        const SizedBox(height: 7),
                        _StarRating(stars: stars),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _LevelStatusIcon(
                  unlocked: unlocked,
                  isCurrent: isCurrent,
                  cleared: cleared,
                  foregroundColor: foregroundColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final lit = index < stars;
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 1),
          child: Icon(
            lit ? Icons.star_rounded : Icons.star_border_rounded,
            size: 11,
            color: lit ? AppColors.ink : AppColors.ink.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }
}

class _LevelStatusIcon extends StatelessWidget {
  const _LevelStatusIcon({
    required this.unlocked,
    required this.isCurrent,
    required this.cleared,
    required this.foregroundColor,
  });

  final bool unlocked;
  final bool isCurrent;
  final bool cleared;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 30,
          child: Icon(
            Icons.play_arrow_rounded,
            size: 19,
            color: AppColors.inverseInk,
          ),
        ),
      );
    }
    if (cleared) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 15,
          color: AppColors.ink,
        ),
      );
    }
    return Icon(
      unlocked ? Icons.arrow_forward_rounded : Icons.lock_rounded,
      size: 17,
      color: foregroundColor.withValues(alpha: unlocked ? 0.6 : 0.5),
    );
  }
}
