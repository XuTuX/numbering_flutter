import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AppRadius.card,
    this.color = AppColors.surface,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: onTap != null
              ? AppColors.ink.withValues(alpha: 0.04)
              : Colors.transparent,
          highlightColor: onTap != null
              ? AppColors.ink.withValues(alpha: 0.025)
              : Colors.transparent,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
