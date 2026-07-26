import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/screens/home/widgets/home_screen_content.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/screens/home/home_screen_flows.dart';
import 'package:numbering/screens/home/level_list/level_tile.dart';

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
        const spacing = 10.0;
        final crossAxisCount =
            ((constraints.maxWidth + spacing) / (94 + spacing))
                .floor()
                .clamp(3, 5);
        final rowCount = (pack.totalLevels / crossAxisCount).ceil();
        final availableRowHeight =
            (constraints.maxHeight - (rowCount - 1) * spacing) / rowCount;
        final tileWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;
        final maxRowHeight = (tileWidth * 0.78).clamp(72.0, 112.0);
        final rowHeight =
            math.max(54.0, math.min(availableRowHeight, maxRowHeight));
        final contentHeight = rowCount * rowHeight + (rowCount - 1) * spacing;

        return GridView.builder(
          key: const ValueKey('level-grid'),
          padding: EdgeInsets.zero,
          physics: contentHeight <= constraints.maxHeight
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
