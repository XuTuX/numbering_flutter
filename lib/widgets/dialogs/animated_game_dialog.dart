import 'package:flutter/material.dart';
import 'package:numbering/theme/app_colors.dart';

class AnimatedGameDialog extends StatelessWidget {
  const AnimatedGameDialog({
    super.key,
    required this.content,
    required this.actions,
  });

  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: ((scale - 0.9) / 0.1).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class GameDialogButton extends StatelessWidget {
  const GameDialogButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.iconColor = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(12),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
