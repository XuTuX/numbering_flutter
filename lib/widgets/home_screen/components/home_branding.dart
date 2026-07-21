import 'package:flutter/material.dart';

import 'package:hexor/theme/app_colors.dart';
import 'package:hexor/theme/app_radius.dart';
import 'package:hexor/theme/app_shadows.dart';

class TopIconButton extends StatelessWidget {
  const TopIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.buttonShadow,
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
