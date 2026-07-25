import 'package:flutter/material.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';

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
