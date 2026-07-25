import 'package:flutter/material.dart';
import 'package:numbering/theme/app_colors.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    this.backLabel = '',
    this.onBack,
    required this.trailing,
    this.leading,
    this.titleWidget,
  });

  final String title;
  final String backLabel;
  final VoidCallback? onBack;
  final Widget trailing;
  final Widget? leading;
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading ??
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: backLabel.isNotEmpty ? backLabel : '뒤로가기',
              onPressed: onBack ?? () {},
            ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: titleWidget ??
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: trailing,
            ),
          ),
        ),
      ],
    );
  }
}

class HintButton extends StatelessWidget {
  const HintButton({
    super.key,
    required this.remainingHints,
    required this.accent,
    required this.onPressed,
  });

  final int remainingHints;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '힌트, $remainingHints회 남음',
      child: SizedBox(
        key: const ValueKey('level-hint-button'),
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.borderLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: remainingHints == 0 ? AppColors.surfaceSoft : accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Text(
                  '$remainingHints',
                  style: TextStyle(
                    color: remainingHints == 0
                        ? AppColors.textSecondary
                        : AppColors.onPrimary,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
